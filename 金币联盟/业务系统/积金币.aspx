<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="积金币.aspx.cs" Inherits="业务系统.积金币" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
</head>
<body style="height: 512px">
    <form id="form1" runat="server">
        <div style="font-family: 楷体; font-size: xx-large; color: #800000; font-weight: 800; height: 78px;">
            积金币<br />
            <br />
            
        </div>
        <div style="height: 291px">
            <asp:Label ID="Label1" runat="server" Text="请输入兑换码"></asp:Label>
            <br />
            <asp:TextBox ID="TextBox1" runat="server" Height="34px" Width="264px"></asp:TextBox>
            <asp:Button ID="Button1" runat="server" Text="获取积分" OnClick="Button1_Click" />
            <br />
            <br />
            <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="False" DataSourceID="SqlDataSource1">
                <Columns>
                    <asp:BoundField DataField="积金币编号" HeaderText="积金币编号" SortExpression="积金币编号" />
                    <asp:BoundField DataField="积金币兑换码" HeaderText="积金币兑换码" SortExpression="积金币兑换码" />
                    <asp:BoundField DataField="积金币时间" HeaderText="积金币时间" SortExpression="积金币时间" />
                    <asp:BoundField DataField="积金币商品名称" HeaderText="积金币商品名称" SortExpression="积金币商品名称" />
                    <asp:BoundField DataField="积金币数目" HeaderText="积金币数目" SortExpression="积金币数目" />
                </Columns>
            </asp:GridView>
            <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:金币联盟ConnectionString %>" SelectCommand="SELECT * FROM [积分明细表]"></asp:SqlDataSource>
        </div>
    </form>
</body>
</html>
