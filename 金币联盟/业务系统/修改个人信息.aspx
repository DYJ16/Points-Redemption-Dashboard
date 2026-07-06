<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="修改个人信息.aspx.cs" Inherits="BiBi.修改个人信息" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
</head>
<body style="background-image: url('333.jpg')">
    <form id="form1" runat="server">
        <div style="height: 44px; font-family: 华文隶书; font-size: xx-large; font-weight: 800; color: #800000;">
            修改个人信息
        </div>
        <div style="height: 376px">

            <asp:Label ID="Label1" runat="server" ForeColor="Maroon" Text="性别："></asp:Label>
            <asp:TextBox ID="TextBox1" runat="server"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label3" runat="server"  ForeColor="Maroon" Text="Email："></asp:Label>
            <asp:TextBox ID="TextBox2" runat="server"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label4" runat="server" ForeColor="Maroon" Text="省份："></asp:Label>
            <asp:TextBox ID="TextBox3" runat="server"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label5" runat="server" ForeColor="Maroon" Text="城市："></asp:Label>
            <asp:TextBox ID="TextBox4" runat="server"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label6" runat="server" ForeColor="Maroon" Text="地区："></asp:Label>
            <asp:TextBox ID="TextBox5" runat="server"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label7" runat="server" ForeColor="Maroon" Text="生日："></asp:Label>
            <asp:TextBox ID="TextBox6" runat="server"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label8" runat="server" ForeColor="Maroon" Text="出生年月："></asp:Label>
            <asp:TextBox ID="TextBox7" runat="server"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label9" runat="server" ForeColor="Maroon" Text="真实姓名："></asp:Label>
            <asp:TextBox ID="TextBox8" runat="server"></asp:TextBox>

            <br />
            <br />
            <asp:Button ID="Button1" runat="server" Text="提交" />

        &nbsp;&nbsp;&nbsp;
            <asp:Button ID="Button2" runat="server" OnClick="Button2_Click" Text="返回个人信息" />

        </div>
      
    </form>
</body>
</html>
