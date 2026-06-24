B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
	#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
	#Macro: Title, Sync Files, ide://run?File=%WINDIR%\System32\Robocopy.exe&Args=..\..\Shared+Files&Args=..\Files&FilesSync=True
#End Region
#Region Macros
	#Macro: Title, Export, ide://run?File=%B4X%\Zipper.jar&Args=%PROJECT_NAME%.zip
	#If B4J
	#Macro: Title, Objects, ide://run?File=%WINDIR%\SysWOW64\explorer.exe&args=%PROJECT%\Objects
	#End If
	'#Macro: Title, GetLibraries, ide://run?File=%ADDITIONAL%\..\B4X\libget.jar&args=%PROJECT%&args=false
#End Region
Sub Class_Globals
	Private xui As XUI
	Private Root As B4XView
	Private lblBack As B4XView
	Private lblCode As B4XView
	Private lblName As B4XView
	Private lblPrice As B4XView
	Private lblTitle As B4XView
	Private lblStatus As B4XView
	Private lblCategory As B4XView
	Private btnNew As B4XView
	Private btnEdit As B4XView
	Private btnDelete As B4XView
	Private Image As B4XImageView
	Private clvRecord As CustomListView
	Private PrefDialog1 As PreferencesDialog
	Private PrefDialog2 As PreferencesDialog
	Private PrefDialog3 As PreferencesDialog
	Private DB As MiniORM
	Private DBS As MiniORMSettings
	Private Viewing As String
	Private Categories As List
	Private CategoryMap As Map
	Private CategoryName As String
	Private Const COLOR_RED As Int = 0xFFFF0000 '-65536 xui.Color_ARGB(255, 255, 0, 0)
	Private Const COLOR_BLUE As Int = 0xFF0000FF '-16776961 xui.Color_ARGB(255, 0, 0, 255)
	Private Const COLOR_MAGENTA As Int = 0xFFFF00FF '-65281 xui.Color_ARGB(255, 255, 0, 255)
	Private Const COLOR_ADD As Int = 0xFF32CD32 '-13447886 xui.Color_ARGB(255, 50, 205, 50)
	Private Const COLOR_EDIT As Int = 0xFF4169E1 '-12490271 xui.Color_ARGB(255, 65, 105, 225)
	Private Const COLOR_DELETE As Int = 0xFFDC143C '-2354116 xui.Color_ARGB(255, 220, 20, 60)
	Private Const COLOR_TRANSPARENT As Int = 0x0 '0 xui.Color_ARGB(0, 0, 0, 0)
	Private Const COLOR_OVERLAY As Int = 0x80000A28 '-2147481048 xui.Color_ARGB(128, 0, 10, 40)
End Sub

Public Sub Initialize
'	B4XPages.GetManager.LogEvents = True
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MainPage")
	B4XPages.SetTitle(Me, "MiniORM")
	ConfigureDatabase
End Sub

Private Sub B4XPage_CloseRequest As ResumableSub
	If xui.IsB4A Then
		'back key in Android
		If PrefDialog1.BackKeyPressed Then Return False
		If PrefDialog2.BackKeyPressed Then Return False
		If PrefDialog3.BackKeyPressed Then Return False
	End If
	If xui.IsB4J Then
		If PrefDialog1.Dialog.Visible Then PrefDialog1.Dialog.Close(xui.DialogResponse_Negative)
		If PrefDialog2.Dialog.Visible Then PrefDialog2.Dialog.Close(xui.DialogResponse_Negative)
		If PrefDialog3.Dialog.Visible Then PrefDialog3.Dialog.Close(xui.DialogResponse_Negative)
	End If
	If Viewing = "Product" Then
		GetCategories
		Return False
	End If
	DB.Close
	Return True
End Sub

Private Sub B4XPage_Appear

End Sub

Private Sub B4XPage_Resize (Width As Int, Height As Int)
	If PrefDialog1.IsInitialized And PrefDialog1.Dialog.Visible Then PrefDialog1.Dialog.Resize(Width, Height)
	If PrefDialog2.IsInitialized And PrefDialog2.Dialog.Visible Then PrefDialog2.Dialog.Resize(Width, Height)
	If PrefDialog3.IsInitialized And PrefDialog3.Dialog.Visible Then PrefDialog3.Dialog.Resize(Width, Height)
End Sub

'Don't miss the code in the B4A Main module + manifest editor.
Private Sub IME_HeightChanged (NewHeight As Int, OldHeight As Int)
	PrefDialog1.KeyboardHeightChanged(NewHeight)
	PrefDialog2.KeyboardHeightChanged(NewHeight)
	PrefDialog3.KeyboardHeightChanged(NewHeight)
End Sub

#If B4J
Private Sub lblBack_MouseClicked (EventData As MouseEvent)
	GetCategories
End Sub
#Else
Private Sub lblBack_Click
	GetCategories
End Sub
#End If

Private Sub clvRecord_ItemClick (Index As Int, Value As Object)
	If Viewing = "Category" Then
		Dim Item As Map = Value
		CategoryName = Item.Get("category_name")
		GetProducts(Item.Get("id"))
	End If
End Sub

Private Sub btnNew_Click
	If Viewing = "Product" Then
		Dim Data As Map = CreateMap("Name": "", "Code": "", "Price": "", "Category": CategoryName, "id": 0)
		ShowDialog2("Add", Data)
	Else
		Dim Data As Map = CreateMap("Name": "", "id": 0)
		ShowDialog1("Add", Data)
	End If
End Sub

Private Sub btnEdit_Click
	Dim Index As Int = clvRecord.GetItemFromView(Sender)
	Dim Item As Map = clvRecord.GetValue(Index)
	If Viewing = "Product" Then
		Dim Data As Map = CreateMap("Name": Item.Get("product_name"), "Code": Item.Get("product_code"), "Price": Item.Get("product_price"), "Category": Item.Get("category_name"), "CategoryId": Item.Get("category_id"), "id": Item.Get("id"))
		ShowDialog2("Edit", Data)
	Else
		Dim Data As Map = CreateMap("Name": Item.Get("category_name"), "id": Item.Get("id"))
		ShowDialog1("Edit", Data)
	End If
End Sub

Private Sub btnDelete_Click
	Dim Index As Int = clvRecord.GetItemFromView(Sender)
	Dim Item As Map = clvRecord.GetValue(Index)
	If Viewing = "Product" Then
		Dim Data As Map = CreateMap("Name": Item.Get("product_name"), "Code": Item.Get("product_code"), "CategoryId": Item.Get("category_id"), "id": Item.Get("id"))
		ShowDialog3(Data)
	Else
		Dim Data As Map = CreateMap("Name": Item.Get("category_name"), "id": Item.Get("id"))
		ShowDialog3(Data)
	End If
End Sub

Public Sub ConfigureDatabase
	DBS.Initialize
	#If MySQL
	DBS.DBType = "MySQL"
	DBS.JdbcUrl = "jdbc:mysql://{DbHost}:{DbPort}/{DbName}?characterEncoding=utf8&useSSL=False"
	DBS.Driver = "com.mysql.cj.jdbc.Driver"
	#Else If MariaDB
	DBS.DBType = "MariaDB"
	DBS.JdbcUrl = "jdbc:mariadb://{DbHost}:{DbPort}/{DbName}"
	DBS.Driver = "org.mariadb.jdbc.Driver"
	#Else
	DBS.DBType = "SQLite"
	DBS.DBFile = "MiniORM.db"
	#If B4J
	DBS.DBDir = File.DirApp
	#Else
	DBS.DBDir = xui.DefaultFolder
	#End If
	#End If
	#If MySQL Or MariaDB
	DBS.DBName = "miniorm"
	DBS.DbHost = "localhost"
	DBS.User = "root"
	DBS.Password = "password"
	#End If
	Try
		DB.Initialize
		DB.Settings = DBS
		DB.ShowExtraLogs = True
		#If MariaDB Or MySQL
		Wait For (DB.ExistAsync) Complete (DbFound As Boolean)
		#Else
		Dim DbFound As Boolean = DB.Exist
		#End If
		If DbFound Then
			#If MariaDB Or MySQL
			LogColor($"(${DBS.DBType}) ${DBS.DBName} database found!"$, COLOR_BLUE)
			#Else
			LogColor($"(${DBS.DBType}) ${DBS.DBFile} database found!"$, COLOR_BLUE)
			#End If
			'File.Delete(DBS.DBDir, DBS.DBFile)
			GetCategories
		Else
			LogColor($"${DBS.DBType} database not found!"$, COLOR_RED)
			CreateDatabase
		End If
	Catch
		Log(LastException.Message)
		LogColor("Error checking database!", COLOR_RED)
		Log("Application is terminated.")
		#If B4J
		ExitApplication
		#End If
	End Try
End Sub

Private Sub CreateDatabase
	LogColor("Creating database...", COLOR_MAGENTA)
	DB.Initialize
	DB.Settings = DBS
	DB.QueryExecute = True
	#If MySQL Or MariaDB
	DB.InitPool
	Wait For (DB.CreateDatabaseAsync) Complete (Success As Boolean)
	#Else
	Dim Success As Boolean = DB.CreateSQLite
	#End If
	If Not(Success) Then
		Log("Database creation failed!")
		Return
	End If
	
	DB.Open
	DB.ShowExtraLogs = True
	'DB.UseTimestamps = True
	DB.QueryExecute = False
	DB.QueryAddToBatch = True
	
	DB.Table = "tbl_categories"
	DB.Columns.Add(CreateMap("Name": "category_name"))
	DB.Create
	
	DB.Columns = Array("category_name")
	DB.InsertWithParams = Array("Hardwares")
	DB.InsertWithParams = Array("Toys")

	DB.Table = "tbl_products"
	DB.Columns.Add(CreateMap("Name": "category_id", "Type": DB.INTEGER))
	DB.Columns.Add(CreateMap("Name": "product_code", "Size": 12))
	DB.Columns.Add(CreateMap("Name": "product_name"))
	DB.Columns.Add(CreateMap("Name": "product_price", "Type": DB.DECIMAL, "Size": "10,2", "Default": 0.0))
	'DB.BLOB = "longblob"
	DB.Columns.Add(CreateMap("Name": "product_image", "Type": DB.BLOB))
	DB.Foreign = "category_id"
	DB.References("tbl_categories", "id")
	DB.Create
	
	DB.Columns = Array("category_id", "product_code", "product_name", "product_price")
	DB.InsertWithParams = Array(2, "T001", "Teddy Bear", 99.9)
	DB.InsertWithParams = Array(1, "H001", "Hammer", 15.75)
	DB.InsertWithParams = Array(2, "T002", "Optimus Prime", 1000)

	Wait For (DB.ExecuteBatchAsync) Complete (Success As Boolean)
	If Success Then
		LogColor("Database is created successfully!", COLOR_BLUE)
	Else
		LogColor("Database creation failed!", COLOR_RED)
		Log(LastException.Message)
	End If
	DB.QueryExecute = True
	
	' Adding an image to blob field
	Dim b() As Byte = File.ReadBytes(File.DirAssets, "icon.png")
	DB.Open
	DB.Table = "tbl_products"
	DB.Columns = Array("product_image")
	DB.Parameters = Array(b)
	DB.Id = 3 ' add id after setting Columns and Parameters
	DB.Save

	GetCategories
End Sub

Private Sub GetCategories
	Try
		DB.Open
		DB.Table = "tbl_categories"
		DB.Query
		clvRecord.Clear
		Categories.Initialize
		CategoryMap.Initialize
		For Each Item As Map In DB.Results
			Categories.Add(Item.Get("category_name"))
			CategoryMap.Put(Item.Get("category_name"), Item.Get("id"))
			clvRecord.Add(CreateCategoryItems(Item, clvRecord.AsView.Width), Item)
		Next
		Viewing = "Category"
		lblBack.Visible = False
		lblTitle.Text = "Category"
		CreateDialog1
		CreateDialog2
		CreateDialog3
	Catch
		xui.MsgboxAsync(LastException.Message, "Error")
	End Try
End Sub

Private Sub GetProducts (CategoryId As Int)
	Try
	DB.Open
	DB.Table = "tbl_products p"
	DB.Columns = Array("p.id", "p.product_code", "p.product_name", "p.product_price", "p.product_image", "p.category_id", "c.category_name")
	DB.Join("LEFT", "tbl_categories c", Array("p.category_id = c.id"))
	DB.WhereParam("c.id = ?", CategoryId)
	DB.ColumnsType = CreateMap("product_image": DB.BLOB)
	DB.Query
	clvRecord.Clear
	For Each Item As Map In DB.Results
		CategoryName = Item.Get("category_name")
		clvRecord.Add(CreateProductItems(Item, clvRecord.AsView.Width), Item)
	Next
	Viewing = "Product"
	lblBack.Visible = True
	lblTitle.Text = CategoryName
	Catch
		xui.MsgboxAsync(LastException.Message, "Error")
	End Try
End Sub

Private Sub CreateCategoryItems (Item As Map, Width As Double) As B4XView
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, 90dip)
	p.LoadLayout("CategoryItem")
	lblName.Text = Item.Get("category_name")
	Return p
End Sub

Private Sub CreateProductItems (Item As Map, Width As Double) As B4XView
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, 180dip)
	p.LoadLayout("ProductItem")
	lblCode.Text = Item.Get("product_code")
	lblName.Text = Item.Get("product_name")
	lblPrice.Text = NumberFormat2(Item.Get("product_price"), 1, 2, 2, True)
	lblCategory.Text = Item.Get("category_name")
	Dim buffer() As Byte = Item.GetDefault("product_image", Array As Byte())
	If buffer.Length = 0 Then
		Image.Clear
	Else
		Dim in As InputStream
		in.InitializeFromBytesArray(buffer, 0, buffer.Length)
		Dim bmx As B4XBitmap
		#If B4A or B4i
		Dim bmp As Bitmap
		bmp.Initialize2(in)
		bmx = bmp
	  	#Else If B4J
		Dim img As Image
		img.Initialize2(in)
		bmx = img
		#End If
		in.Close
		Image.Bitmap = bmx
	End If
	Return p
End Sub

Private Sub CreateDialog1
	PrefDialog1.Initialize(Root, "Category", 300dip, 70dip)
	PrefDialog1.Dialog.OverlayColor = COLOR_OVERLAY
	PrefDialog1.Dialog.TitleBarHeight = 50dip
	PrefDialog1.LoadFromJson(File.ReadString(File.DirAssets, "category.json"))
	PrefDialog1.SetEventsListener(Me, "PrefDialog1") '<-- must add to handle events
End Sub

Private Sub CreateDialog2
	PrefDialog2.Initialize(Root, "Product", 300dip, 250dip)
	PrefDialog2.Dialog.OverlayColor = COLOR_OVERLAY
	PrefDialog2.Dialog.TitleBarHeight = 50dip
	PrefDialog2.LoadFromJson(File.ReadString(File.DirAssets, "product.json"))
	PrefDialog2.SetOptions("Category", Categories)
	PrefDialog2.SetEventsListener(Me, "PrefDialog2") '<-- must add to handle events
End Sub

Private Sub CreateDialog3
	PrefDialog3.Initialize(Root, "Delete", 300dip, 70dip)
	PrefDialog3.Theme = PrefDialog3.THEME_LIGHT
	PrefDialog3.Dialog.OverlayColor = COLOR_OVERLAY
	PrefDialog3.Dialog.TitleBarHeight = 50dip
	PrefDialog3.Dialog.TitleBarColor = COLOR_DELETE
	PrefDialog3.AddSeparator("default")
	PrefDialog3.SetEventsListener(Me, "PrefDialog3") '<-- must add to handle events
End Sub

Private Sub PrefDialog1_BeforeDialogDisplayed (Template As Object)
	AdjustDialogText(PrefDialog1)
End Sub

Private Sub PrefDialog2_BeforeDialogDisplayed (Template As Object)
	AdjustDialogText(PrefDialog2)
End Sub

Private Sub PrefDialog3_BeforeDialogDisplayed (Template As Object)
	AdjustDialogText(PrefDialog3)
End Sub

Private Sub AdjustDialogText (Pref As PreferencesDialog)
	Try
		Dim btnCancel As B4XView = Pref.Dialog.GetButton(xui.DialogResponse_Cancel)
		btnCancel.Width = btnCancel.Width + 20dip
		btnCancel.Left = btnCancel.Left - 20dip
		btnCancel.TextColor = COLOR_RED
		Dim btnOk As B4XView = Pref.Dialog.GetButton(xui.DialogResponse_Positive)
		If btnOk.IsInitialized Then
			btnOk.Width = btnOk.Width + 20dip
			btnOk.Left = btnCancel.Left - btnOk.Width
		End If
	Catch
		Log(LastException.Message)
	End Try
End Sub

Private Sub ShowDialog1 (Action As String, Data As Map)
	PrefDialog1.Title = Action & " Category"
	PrefDialog1.Dialog.TitleBarColor = IIf (Action = "Add", COLOR_ADD, COLOR_EDIT)
	Dim sf As Object = PrefDialog1.ShowDialog(Data, "OK", "CANCEL")
	#If B4J
	Sleep(0)
	PrefDialog1.CustomListView1.sv.Height = PrefDialog1.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	#Else
	PrefDialog1.Dialog.Base.Top = 100dip ' Make it lower
	#End If
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		Dim Id As Int = Data.Get("id")
		Dim Name As String = Data.Get("Name")
		Dim Update As Boolean = Id > 0
		
		DB.Open
		DB.Table = "tbl_categories"
		If Update Then
			DB.WhereParams(Array("category_name = ?", "id <> ?"), Array(Name, Id))
		Else
			DB.WhereParam("category_name = ?", Name)
		End If
		DB.Query
		If DB.Found Then
			xui.MsgboxAsync("Category Name already exist", "Error")
			Return
		End If
			
		DB.Open
		DB.Table = "tbl_categories"
		DB.Columns = Array("category_name")
		If Update Then
			DB.Parameters = Array(Name)
			DB.Id = Id
			DB.Save
			xui.MsgboxAsync("Category updated!", "Edit")
		Else
			DB.ReturnRow = True
			DB.SaveWithParams = Array(Name)
			xui.MsgboxAsync("New category created!", $"ID: ${DB.First.Get("id")}"$)
		End If
		GetCategories
	End If
End Sub

Private Sub ShowDialog2 (Action As String, Data As Map)
	PrefDialog2.Title = Action & " Product"
	PrefDialog2.Dialog.TitleBarColor = IIf(Action = "Add", COLOR_ADD, COLOR_EDIT)
	Dim sf As Object = PrefDialog2.ShowDialog(Data, "OK", "CANCEL")
	Sleep(0)
	PrefDialog2.CustomListView1.sv.Height = PrefDialog2.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		Dim Id As Int = Data.Get("id")
		Dim Name As String = Data.Get("Name")
		Dim Code As String = Data.Get("Code")
		Dim Price As String = Data.Get("Price")
		Dim Category As String = Data.Get("Category")
		Dim CategoryId As Int = CategoryMap.Get(Category)
		Dim Update As Boolean = Id > 0
		
		If IsNumber(Price) = False Then
			xui.MsgboxAsync("Product Price must be a number", "Error")
			Return
		End If
		
		DB.Open
		DB.Table = "tbl_products"
		If Update Then
			DB.WhereParams(Array("product_code = ?", "id <> ?"), Array(Code, Id))
		Else
			DB.WhereParam("product_code = ?", Code)
		End If
		DB.Query
		If DB.Found Then
			xui.MsgboxAsync("Product Code already exist", "Error")
			Return
		End If
		
		DB.Open
		DB.Table = "tbl_products"
		DB.Columns = Array("product_name", "product_code", "product_price", "category_id")
		If Update Then
			DB.Parameters = Array(Name, Code, Price, CategoryId)
			DB.Id = Id
			DB.Save
			xui.MsgboxAsync("Product updated!", "Edit")
		Else
			DB.ReturnRow = True
			DB.SaveWithParams = Array(Name, Code, Price, CategoryId)
			xui.MsgboxAsync("New product created!", $"ID: ${DB.First.Get("id")}"$)
		End If
		
		GetProducts(CategoryId)
	End If
End Sub

Private Sub ShowDialog3 (Data As Map)
	PrefDialog3.Title = "Delete " & Viewing
	Dim sf As Object = PrefDialog3.ShowDialog(Data, "OK", "CANCEL")
	#If B4J
	Sleep(0)
	PrefDialog3.CustomListView1.sv.Height = PrefDialog3.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	#Else
	PrefDialog3.Dialog.Base.Top = 100dip ' Make it lower
	#End If
	#If B4i
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).TextSize = 16 ' Text too small in ios
	#Else
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).TextSize = 15 ' 14
	#End If
	Dim Id As Int = Data.Get("id")
	Dim Name As String = Data.Get("Name")
	If Viewing = "Product" Then
		Dim Code As String = Data.Get("Code")
		Dim CategoryId As Int = Data.Get("CategoryId")
		PrefDialog3.CustomListView1.GetPanel(0).GetView(0).Text = $"${Name} (${Code})"$
	Else
		PrefDialog3.CustomListView1.GetPanel(0).GetView(0).Text = Name
	End If
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).Color = COLOR_TRANSPARENT
	PrefDialog3.CustomListView1.sv.ScrollViewInnerPanel.Color = COLOR_TRANSPARENT
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If Viewing = "Product" Then
			DB.Table = "tbl_products"
		Else
			DB.Table = "tbl_categories"
		End If
		DB.Open
		DB.Find(Id)
		If DB.Found = False Then
			xui.MsgboxAsync(Viewing & " not found", "Error")
			Return
		End If
		
		DB.Open
		DB.Reset
		DB.Id = Id
		DB.Delete
		xui.MsgboxAsync(Viewing &" deleted successfully", "Delete")
		If Viewing = "Product" Then
			GetProducts(CategoryId)
		Else
			GetCategories
		End If
	End If
End Sub