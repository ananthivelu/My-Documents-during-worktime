                              DB ASSIGNMENT -5A

1. What does XML stands for? Does XML support user-defined tags!
    Answer:
    -------
    XML Stands for Extensible Markup Language, Advanced level of HTML.
    In HTML We should use predefined tags or fixed tags, But in XML support user-defined tags. 
    Example:<anyname> </anyname>

2. What is XML declaration tag?
   Answer:
   -------
   <?xml
   version = "version_number"
   encoding = "encoding_declaration"
   standalone = "standalone_status"
   ?>
   version - Specifies the version of the XML standard used.
   encoding- UTF-8, UTF-16, ISO-10646-UCS-2, ISO-10646-UCS-4, ISO-8859-1 to ISO-8859-9, ISO-2022-JP, Shift_JIS, EUC-JP
             UTF-8 is the default encoding we are used.
   standalone-Yes -It does not require any external resources.
              NO  -It informs the parser whether the document relies on the information from an external source, 
                   such as external document type definition (DTD), for its content.

3. What is XQuery?
   Answer:
   -------
   XQuery is a query-based language to retrieve data stored in the form of XML.
   It is language for XML like SQL for SQL Server.

4. Write a code to convert Customers sql table data into XML data.
  The XML file should be displayed as below:
 <Customer CustomerID="ALFKI">
 <CompanyName>Alfreds Futterkiste</CompanyName>
 <address>
 <street>Obere Str. 57</street>
 <city>Berlin</city>
 <zip>12209</zip>
 <country>Germany</country>
 </address>
 <contact>
 <name>Maria Anders</name>
 <title>Sales Representative</title>
 <phone>030-0074321</phone>
 <fax>030-0076545</fax>
 </contact>
 </Customer>
 Answer:
 -------
 SELECT * FROM Customers
 FOR XML PATH, ROOT('Customer-info')

5. Write a code to load XML file data into SQL table using TSQL commands. 
Find the example as below 
 <Customers>
 <Customer>
 <Document>000 000 000</Document>
 <Name>Mary Angel</Name>
 <Address>Your City, YC 1212</Address>
 <Profession>Systems Analyst</Profession>
 </Customer>
 </Customers> 
 Answer:
 -------
DECLARE @xmlDtype NVARCHAR(200)
DECLARE @h INT
SET @xmlDtype = '
<Customer>
  <Id>1</Id>
    <Name>Anu</Name>
	<Document>00-00-00</Document>
	<Profession>Tester</Profession>
    <Address>12,Chennai</Address>
  </Customer>'
/* <Customer>
  <Id>2</Id>
    <Name>Balu</Name>
	<Document>00-00-00</Document>
	<Profession>Tester</Profession>
    <Address>13,Chennai</Address>
  </Customer>
  <Customer>
  <Id>3</Id>
    <Name>Sai</Name>
	<Document>00-00-00</Document>
	<Profession>Manager</Profession>
    <Address>12,Bangalore</Address>
  </Customer>'*/
 
  -- Creating XML Documents
 
Exec sp_xml_preparedocument @h OUTPUT, @xmlDtype
 
-- SELECT statement using OPENXML rowset provider
 
  SELECT * FROM OPENXML (@h, '/Customer', 2) WITH
  (Id VARCHAR(20),
   Name NVARCHAR(20),
   Document NVARCHAR(20),
   Profession VARCHAR(20),
   Address NVARCHAR(20)
  )


 6. Can XML be used for multimedia purpose? 
   Answer:
   -------
   XML can be integrated to all the feasible data format like form text and numbers to multimedia like sound, 
   image to active formats like Java Applets or ActiveX Components.


7. Write a code using FOR XML AUTO clause converts each column of employee table 
into an attribute in the corresponding XML document.
   Answer:
   ------
SELECT * FROM Employees
FOR XML AUTO

8. Define the concept of XPOINTER.
   Answer:
   -------
   XPointer is a language for locating data within an Extensible Markup Language (XML) document based on properties such as 
   location within the document,character content, and attribute values.
   XPointer can be used alone or together with XPath, which is another language for locating data within an XML document.
   XPointer allows links to point to specific parts of an XML document.
   XPointer uses XPath expressions to navigate in the XML document.

9. Can we use graphics in XML? 
   Answer:
   ------
   Yes we can use graphics in XML by using XLink and XPointer specifications. 
   It will support graphic file format like GIF, JPG, TIFF, PNG, CGM, EPS and SVG.

10. Write a code to demonstrate, how OPENXML is used to create a rowset view of an 
    XML document.
	Answer:
	-------
DECLARE @xmlDtype NVARCHAR(200)
DECLARE @h INT
SET @xmlDtype = '
<Bank>
  <Id>1</Id>
          <Name>Anu</Name>
    <Title>New Customer</Title>
  </Bank>'
 
  -- Creating XML Documents
 
Exec sp_xml_preparedocument @h OUTPUT, @xmlDtype
 
-- SELECT statement using OPENXML rowset provider
 
  SELECT * FROM OPENXML (@h, '/Bank', 2) WITH
  (Id VARCHAR(20),
   Name NVARCHAR(20),
  Title NVARCHAR(20)
  )