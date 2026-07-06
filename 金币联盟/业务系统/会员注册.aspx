<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="会员注册.aspx.cs" Inherits="业务系统.会员注册" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
    <style type="text/css">
        .auto-style1 {
            font-size: x-large;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div style="text-align: center">
            <strong><span class="auto-style1">新会员注册</span></strong><br />
            <br />
            <asp:Label ID="Label6" runat="server" Text="编号："></asp:Label>
            <asp:TextBox ID="TextBox5" runat="server" Height="20px" Width="220px"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label1" runat="server" Text="手机号："></asp:Label>
            <asp:TextBox ID="TextBox1" runat="server" Height="20px" Width="200px"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label2" runat="server" Text="密码："></asp:Label>
            <asp:TextBox ID="TextBox2" runat="server" Height="20px" Width="220px"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label3" runat="server" Text="确认密码："></asp:Label>
            <asp:TextBox ID="TextBox3" runat="server" Height="20px" Width="180px"></asp:TextBox>
            <br />
            <br />
            <asp:Label ID="Label4" runat="server" Text="会员昵称："></asp:Label>
            <asp:TextBox ID="TextBox4" runat="server" Height="20px" Width="180px"></asp:TextBox>
            <br />
            <br />
            <asp:Button ID="Button1" runat="server" Height="40px" OnClick="Button1_Click" Text="立即注册" />
            <br />
            <br />
            <asp:Label ID="Label5" runat="server" Text="已注册，请"></asp:Label>
            <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl="~/会员登录.aspx">登录</asp:HyperLink>
            <br />
            <br />
            <asp:Button ID="Button2" runat="server" Text="Button" Visible="False" />
        </div>
    </form>
</body>
</html>
