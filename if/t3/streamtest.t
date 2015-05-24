#charset "us-ascii"

#include <tads.h>
#include <file.h>

enum TestEnum;

class MyClass: object
    myValue = nil
    myLink = nil
    printMyValue()
    {
        "My value is << myValue >>. My link-value is << myLink.myValue() >>. ";
    }
;

modify RexPattern
    streamLoadHeader_(stream)
    {
        return new RexPattern(stream.loadString());
    }
    streamStoreHeader_(stream)
    {
        stream.storeRegistred(RexPattern);
        stream.storeString(getPatternString());
    }
;

function storeStuff(stream)
{
    local objA, objB;
    
    objA = new MyClass;       objB = new MyClass;
    objA.myValue = 'BAR!';    objB.myValue = 'FOO!'; 
    objA.myLink = objB;       objB.myLink = objA;

    stream.storeValue(objA);  stream.storeValue(objB);

    stream.storeValue([1, new Vector(4, [TestEnum, 'b', []]), 3, objB]);

    "Enter a text &emdash; any text: ";
    stream.storeValue(inputLine());

    stream.storeValue(new RexPattern('%<' + '<alpha>{3}%>'));

    stream.closeStream();
    "\bValues stored. ";
}

function loadStuff(stream)
{
    "<< stream.loadValue().printMyValue() >>\n";
    "<< stream.loadValue().printMyValue() >>\n";
    "<< reflectionServices.valToSymbol(stream.loadValue()) >>\n";
    "<< reflectionServices.valToSymbol(stream.loadValue()) >>\n";
    "<< rexReplace(stream.loadValue(), '... where "bar" is any generic expression. ', 'foo', ReplaceAll) >>\n";

    stream.closeStream();
    "\bValues loaded. ";
}

function main(args)
{
    Stream.registerValues(0, TadsObject, Vector, RexPattern, MyClass, TestEnum, &myValue, &myLink);

    "Choose one:\n
    &emsp;1. Load values from \"test.dat\".\n
    &emsp;2. Store values in \"test.dat\".\b
    &gt;\ ";
    
    switch (inputLine())
    {
    case '1': loadStuff ( new FileStream(File.openRawFile('test.dat', FileAccessRead )) ); break;
    case '2': storeStuff( new FileStream(File.openRawFile('test.dat', FileAccessWrite)) ); break;
    default:  "\bCouldn't make up your mind, eh?\n";
    }
}
