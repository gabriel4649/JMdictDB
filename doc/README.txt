This directory contains documentation for the JMdictDB project.

Currently this consists of an Open Office Writer document 
that describes the JMdict database schema, a Dia diagram that 
illustrates the same, and a directory of "issue" files that 
provide a basic issue-tracking sytem.

There is a Makefile that will generate html and pdf versions
of the OO document, and a png of the database diagram.  On 
Windows, the Gnu make program is required to use the Makefile. 
See the top-level directory README.txt for more information.

The database diagram was constructed using Dia (an Open Source
Visio-like diagranmming tool).  Dia is available for Windows 
but the schema.dia file here was created on a Linux system and 
looks horrible when opened in Dia under Windows.  So "make schema" 
should be done on a Linux system unless you want to manually 
adjust the positions of everything in the diagram on Windows.

I do not have OpenOffice installed on a Windows machine, so
that too has been run only under Linux.  To get OpenOffice to 
export to html and pdf from the commandline requires creating
creating a helper macro, at least in OpenOffice-2.0.  
To add the macro do the following:

...TBD...
The following is the StarBasic code used:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Sub ExportDoc( cFile, outtype )
    ' Open the document.
    ' Just blindly assume that the document is of a type that OOo will
    '  correctly recognize and open -- without specifying an import filter.
    cURL = ConvertToURL( cFile )
    oDoc = StarDesktop.loadComponentFromURL( cURL, "_blank", 0, _
        Array( MakePropertyValue( "Hidden", True ), ) )

    ' Save the document using a filter.
    cFile = Left( cFile, Len( cFile ) - 4 ) + ("." & outtype)
    cURL = ConvertToURL( cFile )
    if outtype = "pdf" then filter =  "writer_pdf_Export"
    if outtype = "html" then filter = "HTML"
    oDoc.storeToURL( cURL, Array( MakePropertyValue( "FilterName", filter ), ) )
    oDoc.close( True )
    End Sub

Function MakePropertyValue( Optional cName As String, Optional uValue ) As com.sun.star.beans.PropertyValue
    Dim oPropertyValue As New com.sun.star.beans.PropertyValue
    If Not IsMissing( cName ) Then
        oPropertyValue.Name = cName
        EndIf
    If Not IsMissing( uValue ) Then
        oPropertyValue.Value = uValue
        EndIf
    MakePropertyValue() = oPropertyValue
    End Function

Sub test( cArg )
    Print "|"+cArg+"|"
    End Sub
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
