<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="购物车.aspx.cs" Inherits="业务系统.购物车" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
    <style type="text/css">
        #form1 {
            height: 556px;
        }
    </style>
</head>
<body style="height: 635px">
    <form id="form1" runat="server">
        <p style="font-family: 楷体; font-size: xx-large; font-weight: 800; font-style: inherit; color: #800000; text-decoration: none">
&nbsp;&nbsp;&nbsp;&nbsp; 购物车&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
            <asp:Button ID="main" runat="server" Text="首页" Width="50px" />
&nbsp;<asp:Button ID="personal" runat="server" Text="个人中心" />
&nbsp;</p>
        <div>
            <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="False" BackColor="White" BorderColor="#CCCCCC" BorderStyle="None" BorderWidth="1px" CellPadding="3" DataSourceID="SqlDataSource1" OnSelectedIndexChanged="GridView1_SelectedIndexChanged1">
                <Columns>
                    <asp:TemplateField HeaderText="全选">
                        <HeaderTemplate>
                            <asp:CheckBox ID="CheckBox2" runat="server" onclick="javascript: SelectAllCheckboxes(this);" Text="全选/取消" ToolTip="按一次全选，再按一次取消全选"/>
                        </HeaderTemplate>
                        <ItemTemplate>
                            <asp:CheckBox ID="CheckBox1" runat="server" Text="全选" OnCheckedChanged="CheckBox1_CheckedChanged" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="GiftId" HeaderText="GiftId" SortExpression="GiftId" />
                    <asp:BoundField DataField="GiftName" HeaderText="GiftName" SortExpression="GiftName" />
                    <asp:BoundField DataField="GiftCoin" HeaderText="GiftCoin" SortExpression="GiftCoin" />
                    <asp:BoundField DataField="GiftNum" HeaderText="GiftNum" SortExpression="GiftNum" />
                </Columns>
                <FooterStyle BackColor="White" ForeColor="#000066" />
                <HeaderStyle BackColor="#006699" Font-Bold="True" ForeColor="White" />
                <PagerStyle BackColor="White" ForeColor="#000066" HorizontalAlign="Left" />
                <RowStyle ForeColor="#000066" />
                <SelectedRowStyle BackColor="#669999" Font-Bold="True" ForeColor="White" />
                <SortedAscendingCellStyle BackColor="#F1F1F1" />
                <SortedAscendingHeaderStyle BackColor="#007DBB" />
                <SortedDescendingCellStyle BackColor="#CAC9C9" />
                <SortedDescendingHeaderStyle BackColor="#00547E" />
            </asp:GridView>
            <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:金币联盟ConnectionString %>" SelectCommand="SELECT * FROM [Gift]"></asp:SqlDataSource>
            <br />
            <asp:Panel ID="pnlCart" runat="server">
    <br />
    <asp:Label ID="lblError" runat="server" ForeColor="Red"></asp:Label><br />
    <asp:Label ID="lblHint" runat="server" ForeColor="Green"></asp:Label><br />
    总价：<asp:Label ID="lblTotalPrice" runat="server"></asp:Label>
    &nbsp;&nbsp;
    <asp:Button ID="btnDelete" runat="server" Text="删除商品" OnClick="btnDelete_Click" style="height: 27px" />
    &nbsp;&nbsp;&nbsp;&nbsp;
    <asp:Button ID="btnClear" runat="server" Text="清空购物车" OnClick="btnClear_Click" />
    &nbsp;&nbsp;&nbsp;<asp:Button ID="btnComputeAgain" runat="server" Text="重新计算" OnClick="btnComputeAgain_Click" style="height: 27px" />
    &nbsp;
    <asp:Button ID="btnSettle" runat="server" Text="结算" OnClick="btnSettle_Click" />
  </asp:Panel></div>
    </form>
</body>
</html>
<script type="text/javascript">
    function SelectAllCheckboxes(spanChk)
    {
        elm=document.forms[0];
        for(i=0;i<= elm.length -1;i++)
        {
            if(elm[i].type=="checkbox" && elm[i].id!=spanChk.id)
            {
                if(elm.elements[i].checked!=spanChk.checked)
                    elm.elements[i].click();
            }
        }
    }
</script>
