#charset "us-ascii"

/*
 *   Stream Module 1.1
 *   -----------------
 *
 *   This module implements a Stream class for storing arbitrary values.
 *   
 *   For documentation, updates, etc., visit
 *   http://kwi.homepage.dk/kwif/streams.htm
 *
 *   Send comments, questions, suggestions and bug-reports to kwi@it.dk.
 *
 *   -- Soren J. Lovborg
 */

#include <tads.h>
#include <charset.h>

/* Pseudo-types used internally for storing and retrieving values */
#define TypeObjectRef      0xFD
#define TypeObjectData     0xFE
#define TypeRegistredValue 0xFF

/* ------------------------------------------------------------------------ */

class EStreamError: Exception
    construct(msg_) { msg = msg_; }
    msg = nil
    displayException = "Stream error: << msg >>"
;

class EStreamUnsupportedMethod: EStreamError
    construct() { inherited('Stream does not support method'); }
;

class EStreamLoadUnregistredValue: EStreamError
    construct(id_) { id = id_; }
    id = nil
    displayException()
    {
        "Stream error: Value-ID << id >> is unregistred and cannot be loaded";
    }
;

class EStreamStoreUnregistredValue: EStreamError
    construct(val_) { val = val_; }
    val = nil
    displayException()
    {
        "Stream error: Value ";
        if (mainGlobal.reflectionObj)
            "<< mainGlobal.reflectionObj.valToSymbol(val) >>";
        else "of type << dataType(val) >>";
        " is not unregistred and cannot be stored";
    }
;

/* ------------------------------------------------------------------------ */

class Stream: object
    /*
     *  The character set used by _some_ stream subclasses for streaming
     *  strings. By default, all streams use UTF-8, which TADS 3 is also
     *  using internally.
     */
    streamCharset = static new CharacterSet('UTF-8')
    
    registerValues(id, [vals])
    {
        for (local i = 1; i <= vals.length(); i++)
        {
            if (registredValuesByID_.isKeyPresent(id))
                throw new EStreamError('The stream value-ID ' + id
                    + ' is already associated with another value');

            registredValuesByVal_[vals[i]] = id;
            registredValuesByID_[id] = vals[i];

            id++;
        }
    }
    
    storeList(lst)
    {
        storeWord(lst.length());
        for (local i = 1, local len = lst.length(); i <= len; i++)
            storeValue(lst[i]);
    }
    loadList()
    {
        local len = loadWord();
        local lst = new Vector(len, len);
        for (local i = 1; i <= len; i++) lst[i] = loadValue();
        return lst.toList();
    }

    /*
     *  The generic string-streaming methods are not actually used
     *  by any of the included subclasses.
     */
    storeString(str)
    {
        str = str.toUnicode();
        storeWord(str.length());
        for (local i = 1; i <= str.length(); i++) storeWord(str[i]);
    }
    loadString()
    {
        local len = loadWord();
        local str = new Vector(len, len);
        for (local i = 1; i <= len; i++) str[i] = loadWord();
        return makeString(str.toList());
    }
    
    storeRegistred(val)
    {
        local id = registredValuesByVal_[val];
        if (id == nil) cannotStoreValue(val);
        else storeInteger(id);
    }
    loadRegistred()
    {
        local id = loadInteger();
        if (!registredValuesByID_.isKeyPresent(id))
            throw new EStreamLoadUnregistredValue(id);
        return registredValuesByID_[id];
    }
    
    storeValue(val)
    {
        local id = registredValuesByVal_[val];
        if (id != nil)
        {
            storeByte(TypeRegistredValue);
            storeInteger(id);
            return;
        }
        
        local type = dataType(val);
        if (type == TypeObject) { storeObject_(val); return; }

        storeByte(type);

        switch(type)
        {
        case TypeNil:
        case TypeTrue:
            return;
            
        case TypeInt:
            storeInteger(val);
            return;

        case TypeSString:
            storeString(val);
            return;
            
        case TypeList:
            storeList(val);
            return;
            
/*
        case TypeFuncPtr:
        case TypeEnum:
        case TypeNativeCode:
        case TypeProp:
*/
        default:
            cannotStoreValue(val);
        }
    }

    loadValue()
    {
        local x = loadByte();
        switch(x)
        {
        case TypeRegistredValue:
            x = loadInteger();
            if (!registredValuesByID_.isKeyPresent(x))
                throw new EStreamLoadUnregistredValue(x);
            return registredValuesByID_[x];
        
        case TypeNil: return nil;
        case TypeTrue: return true;
        case TypeInt: return loadInteger();

        case TypeSString:
            return loadString();
            
        case TypeList:
            return loadList();

        case TypeObjectRef:
        case TypeObjectData:
            return loadObject_(x);

/*            
        case TypeFuncPtr:
        case TypeEnum:
        case TypeNativeCode:
        case TypeProp:
*/
        default:
            return cannotLoadType(x);
        }
    }

    cannotStoreValue(val)
    {
        throw new EStreamStoreUnregistredValue(val);
    }
    cannotLoadType(type)
    {
        throw new EStreamError('Cannot load values of type ' + type);
    }

    /* ------------------------------------------------ */
    /* Stream primitives */

    storeByte(x)    { throw new EStreamUnsupportedMethod(); }
    storeWord(x)    { throw new EStreamUnsupportedMethod(); }
    storeInteger(x) { throw new EStreamUnsupportedMethod(); }
    loadByte()      { throw new EStreamUnsupportedMethod(); }
    loadWord()      { throw new EStreamUnsupportedMethod(); }
    loadInteger()   { throw new EStreamUnsupportedMethod(); }

    getSize()       { throw new EStreamUnsupportedMethod(); }
    getPosition()   { throw new EStreamUnsupportedMethod(); }
    setPosition(pos){ throw new EStreamUnsupportedMethod(); }
    closeStream()   { /* Do nothing */ }

    /* ------------------------------------------------ */
    /* Private data */

    registredValuesByVal_ = static new LookupTable()
    registredValuesByID_  = static new LookupTable()

    storedObjectsNextID_ = -0x7FFFFFFF
    storedObjectsByID_   = perInstance(new LookupTable())
    storedObjectsByVal_  = perInstance(new LookupTable())

    /* ------------------------------------------------ */
    /*  Internal methods for storing and loading objects.
     *  (Call storeValue/loadValue instead of these.)
     */
    storeObject_(obj)
    {
        local id = storedObjectsByVal_[obj];
        if (id != nil)
        {
            storeByte(TypeObjectRef);
            storeInteger(id);
        }
        else
        {
            // If we've not already stored (or, at least, begun storing)
            // this object, store it now.

            storedObjectsByVal_[obj] = id = storedObjectsNextID_++;
            storedObjectsByID_[id] = obj;

            storeByte(TypeObjectData);
            storeInteger(id);
            obj.streamStoreHeader_(self);

            obj.streamStoreData_(self);
        }
    }
    loadObject_(type)
    {
        local obj, id = loadInteger();
        
        if (type == TypeObjectRef)
        {
            obj = storedObjectsByID_[id];
            if (!obj) throw new EStreamError('Object-reference to undefined object');
            return obj;
        }
        
        obj = loadRegistred();
        if (dataType(obj) != TypeObject) throw new EStreamError('Object expected, stream corrupted');
        obj = obj.streamLoadHeader_(self);

        storedObjectsByVal_[obj] = id;
        storedObjectsByID_[id]   = obj;
        
        obj.streamLoadData_(self);
        return obj;
    }
;

/* ------------------------------------------------------------------------ */
/*
 *  Provide some stream implementations.
 */

class ByteArrayStream: Stream
    array = nil
    position_ = 0

    construct(array_)
    {
        array = array_;
    }

    storeString(str)
    {
        local x = str.mapToByteArray(streamCharset);
        local len = x.length();
        storeWord(len);
        array.copyFrom(x, 1, position_ + 1, len);
        position_ += len;
    }
    
    loadString()
    {
        local x = new ByteArray(array, position_ + 1, loadWord());
        position_ += x.length();
        return x.mapToString(streamCharset);
    }

    storeByte(x)    { array[++position_] = x; }
    storeWord(x)    { array.writeInt((position_ += 2) - 1, FmtInt16LE, x); }
    storeInteger(x) { array.writeInt((position_ += 4) - 3, FmtInt32LE, x); }
    loadByte()      { return array[++position_]; }
    loadWord()      { return array.readInt((position_ += 2) - 1, FmtInt16LE); }
    loadInteger()   { return array.readInt((position_ += 4) - 3, FmtInt32LE); }

    getSize = (array.length())
    getPosition = (position_)
    setPosition(pos) { position_ = pos; }

    closeStream() { }
;

class VectorStream: Stream
    vector = nil
    position_ = 0

    construct(vector_)
    {
        vector = vector_;
    }

    storeString(str) { vector[++position_] = str; }
    loadString()     { return vector[++position_]; }

    storeByte(x)    { vector[++position_] = x; }
    storeWord(x)    { vector[++position_] = x; }
    storeInteger(x) { vector[++position_] = x; }
    loadByte()      { return vector[++position_]; }
    loadWord()      { return vector[++position_]; }
    loadInteger()   { return vector[++position_]; }

    getSize = (vector.length())
    getPosition = (position_)
    setPosition(pos) { position_ = pos; }

    closeStream() { }
;

class FileStream: Stream
    file = nil
    tmpArray = static new ByteArray(4)
    construct(file_)
    {
        file = file_;
    }

    storeString(str)
    {
        local x = str.mapToByteArray(streamCharset);
        storeWord(x.length());
        file.writeBytes(x);
    }
    
    loadString()
    {
        local array = new ByteArray(loadWord());
        file.readBytes(array);
        return array.mapToString(streamCharset);
    }

    storeByte(x)    { tmpArray[1] = x;                     file.writeBytes(tmpArray, 1, 1); }
    storeWord(x)    { tmpArray.writeInt(1, FmtInt16LE, x); file.writeBytes(tmpArray, 1, 2); }
    storeInteger(x) { tmpArray.writeInt(1, FmtInt32LE, x); file.writeBytes(tmpArray, 1, 4); }
    loadByte()      { read_(1); return tmpArray[1]; }
    loadWord()      { read_(2); return tmpArray.readInt(1, FmtInt16LE); }
    loadInteger()   { read_(4); return tmpArray.readInt(1, FmtInt32LE); }
    read_(byteCnt)
    {
        if (file.readBytes(tmpArray, 1, byteCnt) < byteCnt) throw new EStreamError('Reached EOF');
    }

    getSize = (file.getFileSize())
    getPosition = ( file.getPos() )
    setPosition(pos) { file.setPos(pos); }

    closeStream() { file.closeFile(); }
;

/* ------------------------------------------------------------------------ */
/*
 *  Modify intrinsic classes to support streaming.
 */

modify Object
    streamLoadHeader_(stream)
    {
        throw new EStreamError('Invalid superclass for stream-load');
    }
    streamStoreHeader_(stream)
    {
        throw new EStreamError('Invalid superclass for stream-store');
    }
    streamStoreData_(stream) { }
    streamLoadData_(stream) { }
;

modify Vector
    streamLoadHeader_(stream)
    {
        local x = stream.loadWord;
        return new Vector(x, x);
    }
    streamStoreHeader_(stream)
    {
        stream.storeRegistred(Vector);
        stream.storeWord(length());
    }
    streamLoadData_(stream)
    {
        for (local i = 1; i <= length(); i++)
        {
            self[i] = stream.loadValue();
        }
    }
    streamStoreData_(stream)
    {
        for (local i = 1; i <= length(); i++)
        {
            stream.storeValue(self[i]);
        }
    }
;

modify TadsObject
    streamStoreHeader_(stream)
    {
        stream.storeRegistred(TadsObject);
        stream.storeList(getSuperclassList());
    }
    streamLoadHeader_(stream)
    {
        return TadsObject.createInstanceOf(stream.loadList()...);
    }
    streamLoadData_(stream)
    {
        for (local len = stream.loadWord(); len >= 1; len--)
        {
            local prop = stream.loadValue();
            self.(prop) = stream.loadValue();
        }
    }
    streamStoreData_(stream)
    {
        local lst = streamStoreProps_();
        stream.storeWord(lst.length());

        foreach (local prop in lst)
        {
            stream.storeValue(prop);
            stream.storeValue(self.(prop));
        }
    }
    streamStoreProps_ = (getPropList())
;

/* ------------------------------------------------------------------------ */