<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="会员登录.aspx.cs" Inherits="业务系统.会员登录" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
    <style type="text/css">
        .auto-style1 {
            text-align: center;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="auto-style1">
            <asp:Label ID="Label1" runat="server" style="font-size: x-large; font-weight: 700" Text="会员登录金币联盟"></asp:Label>
            <br />
            <br />
            <asp:Label ID="Label2" runat="server" Text="手机号："></asp:Label>
            <asp:TextBox ID="TextBox1" runat="server" Height="20px" OnTextChanged="TextBox1_TextChanged" Width="200px"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label3" runat="server" Text="密码："></asp:Label>
            <asp:TextBox ID="TextBox2" runat="server" Height="20px" OnTextChanged="TextBox1_TextChanged" Width="220px"></asp:TextBox>
            <br />
            <br />
            <asp:Button ID="Button1" runat="server" Height="40px" OnClick="Button1_Click" Text="登录" />
            <br />
            <br />
            <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl="~/会员注册.aspx">还没注册！</asp:HyperLink>
            <br />
            <br />
            <asp:HyperLink ID="HyperLink2" runat="server">忘记密码？</asp:HyperLink>
            <br />
            <br />
            <asp:Label ID="Label4" runat="server"></asp:Label>
        </div>
    </form>
</body>
</html>
