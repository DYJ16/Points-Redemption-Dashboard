<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="个人信息.aspx.cs" Inherits="BiBi.WebForm1" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
    <style type="text/css">
        .auto-style1 {
            font-size: x-large;
        }
        .auto-style2 {
            text-align: left;
        }
    </style>
    </head>
<body style="background-image: url('http://localhost:56025/333.jpg')">
    <form id="form1" runat="server">
        <div style="height: 456px; width: 966px" class="auto-style2">
            <div>
                &nbsp;<asp:Label ID="Label11" runat="server" BorderStyle="None" ForeColor="Black" style="font-size: x-large" Text="会员个人信息"></asp:Label>
            <br />
            <br />
                <br />
                &nbsp;<br />
            <asp:Label ID="Label12" runat="server" Text="会员ID："></asp:Label>
                <asp:Label ID="Label14" runat="server"></asp:Label>
                &nbsp;&nbsp;&nbsp;&nbsp;<br />
                <br />
            <asp:Label ID="Label1" runat="server" Text="会员昵称："></asp:Label>
                <asp:Label ID="Label15" runat="server"></asp:Label>
                &nbsp;<br />
            <br />
            <asp:Label ID="Label7" runat="server" Text="性别："></asp:Label>
                <asp:Label ID="Label16" runat="server"></asp:Label>
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                <br />
                <br />
            <asp:Label ID="Label2" runat="server" Text="E-mail："></asp:Label>
                <asp:Label ID="Label17" runat="server"></asp:Label>
            <br />
            <br />
            <asp:Label ID="Label3" runat="server" Text="省份："></asp:Label>
                <asp:Label ID="Label18" runat="server"></asp:Label>
                <br />
                &nbsp;&nbsp;&nbsp;&nbsp;<br />
                <asp:Label ID="Label23" runat="server" Text="城市："></asp:Label>
                <asp:Label ID="Label24" runat="server"></asp:Label>
                &nbsp;<br />
                <br />
                <asp:Label ID="Label25" runat="server" Text="地区："></asp:Label>
                <asp:Label ID="Label26" runat="server"></asp:Label>
                <br />
                <br />
            <asp:Label ID="Label13" runat="server" Text="生日："></asp:Label>
                <asp:Label ID="Label19" runat="server"></asp:Label>
            <br />
            <br />
            <asp:Label ID="Label4" runat="server" Text="手机号码："></asp:Label>
                <asp:Label ID="Label20" runat="server"></asp:Label>
                &nbsp;&nbsp;&nbsp;
                <br />
                <br />
            <asp:Label ID="Label6" runat="server" Text="出生年月："></asp:Label>
                <asp:Label ID="Label21" runat="server"></asp:Label>
                &nbsp;&nbsp;
            <br />
            <br />
            <asp:Label ID="Label8" runat="server" Text="真实姓名："></asp:Label>
                <asp:Label ID="Label22" runat="server"></asp:Label>
&nbsp;&nbsp;&nbsp;
            <br />
            <br />
            <asp:Button ID="Button1" runat="server" Height="25px" Text="修改" Width="52px" OnClick="Button1_Click1" />
&nbsp;&nbsp;<asp:Button ID="Button4" runat="server" Height="25px" OnClick="Button4_Click" Text="完善个人信息" Width="118px" />
            &nbsp;&nbsp;
            <br />
            <br />
            <span class="auto-style1">个人订单信息<br />
            </span>
            <br />
            </div>
            <asp:GridView ID="GridView1" runat="server" OnSelectedIndexChanged="GridView1_SelectedIndexChanged">
            </asp:GridView>
        </div>
    </form>
</body>
</html>
