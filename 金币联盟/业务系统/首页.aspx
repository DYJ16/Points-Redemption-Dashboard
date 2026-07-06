<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="首页.aspx.cs" Inherits="WebApplication2.index" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
    <style type="text/css">
        .auto-style1 {
            width: 62%;
            margin-left: 64px;
            margin-right: 0px;
        }
        .auto-style5 {
            height: 1134px;
            margin-top: 0px;
        }
        .auto-style21 {
            width: 265px;
            height: 285px;
            text-align: center;
        }
        .auto-style22 {
            width: 265px;
            text-align: center;
        }
        .auto-style25 {
            width: 261px;
            height: 285px;
            text-align: center;
        }
        .auto-style26 {
            width: 261px;
            text-align: center;
        }
        .auto-style27 {
            width: 255px;
            height: 285px;
            text-align: center;
        }
        .auto-style28 {
            width: 255px;
            text-align: center;
        }
        .auto-style29 {
            height: 61px;
            width: 1611px;
            text-align: center;
        }
        .auto-style30 {
            height: 2000px;
            margin-right: 0px;
        }
        .auto-style32 {
            width: 100%;
            height: 267px;
            background-image: url('Images/ZS.png');
        }
        .auto-style33 {
            height: 141px;
            width: 1617px;
            text-align: center;
        }
        .auto-style34 {
            text-align: center;
        }
        .auto-style35 {
            text-align: right;
        }
    </style>
</head>
<body style="height: 487px; width: 1612px; text-align: center; margin:0px auto ">
    <form id="form1" runat="server" style="background-color: #635C85; " class="auto-style30">
        <div style="background-color: #B87442; " class="auto-style29">
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<asp:LinkButton ID="LinkButton6" runat="server" ForeColor="White">免费注册</asp:LinkButton>
&nbsp;|
            <asp:LinkButton ID="LinkButton7" runat="server" ForeColor="White">嘿~要登录哦3</asp:LinkButton>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            <asp:Image ID="Image1" runat="server" Height="60px" ImageUrl="~/JBI.jpg" Width="60px" style="text-align: center" />
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<asp:LinkButton ID="LinkButton8" runat="server" ForeColor="White">联盟首页</asp:LinkButton>
&nbsp;&nbsp;
            <asp:LinkButton ID="LinkButton9" runat="server" ForeColor="White">我的购物车</asp:LinkButton>
&nbsp;&nbsp;
            <asp:LinkButton ID="LinkButton10" runat="server" ForeColor="White">个人收藏夹</asp:LinkButton>
&nbsp;&nbsp;
            <asp:LinkButton ID="LinkButton11" runat="server" ForeColor="White">网站导航</asp:LinkButton>
            <br />
            <br />
            <br />
        </div>
        <p style="height: 299px; background-color: #FFFFFF; margin-bottom: 0px;">
            <asp:Image ID="Image2" runat="server" Height="299px" ImageUrl="~/ZS.png" style="margin-bottom: 0px; text-align: center;" Width="1617px" BackGroundImageLayout="Strecth" SizeMode="StretchImage"/>
        </p>
        <div class="auto-style35">
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
        <asp:Button ID="Button1" runat="server" ForeColor="#67497D" Height="30px" Text="积金币" BackColor="#DBB400" />
&nbsp;&nbsp;
        <asp:Button ID="Button2" runat="server" ForeColor="#67497D" Height="30px" Text="兑好礼" BackColor="#DBB400" />
&nbsp;&nbsp;
        <asp:Button ID="Button3" runat="server" ForeColor="#67497D" Height="29px" Text="享活动" BackColor="#DBB400" />
        &nbsp;
        </div>
        <p class="auto-style34">

        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;
            <asp:Button ID="Button4" runat="server" Height="27px" Text="首页" Width="79px" BackColor="White" />
&nbsp;&nbsp;
            <asp:Button ID="Button5" runat="server" Height="26px" Text="礼品中心" Width="79px" BackColor="White" />
&nbsp;&nbsp;
            <asp:Button ID="Button6" runat="server" Height="25px" Text=" 购物车" Width="79px" BackColor="White" />
&nbsp;&nbsp;
            <asp:Button ID="Button7" runat="server" Height="25px" Text="个人中心" Width="79px" BackColor="White" OnClick="Button7_Click" />
            <div class="auto-style5" style="background-color: #DBB400;" align="center">
            &nbsp;<table align="center" class="auto-style1">
                <tr>
                    <td class="auto-style21">
                        <asp:Image ID="Image3" runat="server" Height="285px" ImageUrl="~/1.jpg" Width="280px" />
                        <br />
                        <asp:Label ID="Label7" runat="server" Text="9999金币" ForeColor="#660066"></asp:Label>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <asp:Button ID="Button8" runat="server" ForeColor="Red" Text="❤" />
                        <asp:Button ID="Button9" runat="server" ForeColor="#67497D" Height="21px" Text="加入购物车" Width="99px" />
                        <br />
                        <br />
                        <asp:Label ID="Label8" runat="server" Text="小霸王K10全网通4G网络Wifi学习机" ForeColor="#660066"></asp:Label>
                    </td>
                    <td class="auto-style27">
                        <asp:Image ID="Image6" runat="server" Height="285px" ImageUrl="~/2.jpg" Width="280px" />
                        <br />
                        <asp:Label ID="Label9" runat="server" Text="1478金币" ForeColor="#660066"></asp:Label>
                        &nbsp;&nbsp;&nbsp;
                        <asp:Button ID="Button10" runat="server" ForeColor="Red" Text="❤" />
                        <asp:Button ID="Button11" runat="server" ForeColor="#67497D" Height="21px" Text="加入购物车" Width="99px" />
                        <br />
                        <br />
                        <asp:Label ID="Label17" runat="server" Text="泰科拉时光机复古T038云山桃花芯" ForeColor="#660066"></asp:Label>
                    </td>
                    <td class="auto-style25">
                        <asp:Image ID="Image9" runat="server" Height="285px" ImageUrl="~/3.jpg" Width="280px" />
                        <br />
                        <asp:Label ID="Label10" runat="server" Text="198金币" ForeColor="#660066"></asp:Label>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <asp:Button ID="Button12" runat="server" ForeColor="Red" Text="❤" />
                        <asp:Button ID="Button13" runat="server" ForeColor="#67497D" Height="21px" Text="加入购物车" Width="99px" />
                        <br />
                        <br />
                        <asp:Label ID="Label18" runat="server" Text="现代简约ins风少女家用梳妆椅" ForeColor="#660066"></asp:Label>
                    </td>
                </tr>
                <tr>
                    <td class="auto-style22">
                        <asp:Image ID="Image4" runat="server" Height="285px" ImageUrl="~/4.jpg" Width="280px" />
                        <br />
                        <asp:Label ID="Label11" runat="server" Text="7099金币" ForeColor="#660066"></asp:Label>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <asp:Button ID="Button14" runat="server" ForeColor="Red" Text="❤" />
                        <asp:Button ID="Button15" runat="server" ForeColor="#67497D" Height="21px" Text="加入购物车" Width="99px" />
                        <br />
                        <asp:Label ID="Label19" runat="server" Text="Sharp LCD-70MY5100A 70寸4K网络智能液晶电视机" ForeColor="#660066"></asp:Label>
                        <br />
                    </td>
                    <td class="auto-style28">
                        <asp:Image ID="Image7" runat="server" Height="285px" ImageUrl="~/5.jpg" Width="280px" />
                        <br />
                        <asp:Label ID="Label12" runat="server" Text="508金币" ForeColor="#660066"></asp:Label>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <asp:Button ID="Button16" runat="server" ForeColor="Red" Text="❤" />
                        <asp:Button ID="Button17" runat="server" ForeColor="#67497D" Height="21px" Text="加入购物车" Width="99px" />
                        <br />
                        <br />
                        <asp:Label ID="Label20" runat="server" Text="BOLON偏光男士金属复古太阳镜" ForeColor="#660066"></asp:Label>
                        <br />
                    </td>
                    <td class="auto-style26">
                        <asp:Image ID="Image10" runat="server" Height="285px" ImageUrl="~/6.jpg" Width="280px" />
                        <br />
                        <asp:Label ID="Label13" runat="server" Text="39999金币" ForeColor="#660066"></asp:Label>
                        &nbsp;&nbsp;&nbsp;
                        <asp:Button ID="Button18" runat="server" ForeColor="Red" Text="❤" />
                        <asp:Button ID="Button19" runat="server" ForeColor="#67497D" Height="21px" Text="加入购物车" Width="99px" />
                        <br />
                        <asp:Label ID="Label21" runat="server" Text="SCOTT 2019SPARK RC900 TEAM碳纤维软尾山地自行车" ForeColor="#660066"></asp:Label>
                        <br />
                    </td>
                </tr>
                <tr>
                    <td class="auto-style22">
                        <asp:Image ID="Image5" runat="server" Height="285px" ImageUrl="~/7.jpg" Width="280px" />
                        <br />
                        <asp:Label ID="Label14" runat="server" Text="198金币" ForeColor="#660066"></asp:Label>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <asp:Button ID="Button20" runat="server" ForeColor="Red" Text="❤" />
                        <asp:Button ID="Button21" runat="server" ForeColor="#67497D" Height="21px" Text="加入购物车" Width="99px" />
                        <br />
                        <asp:Label ID="Label22" runat="server" Text="Edifier W25BT蓝牙耳机苹果无线运动耳塞" ForeColor="#660066"></asp:Label>
                        <br />
                    </td>
                    <td class="auto-style28">
                        <asp:Image ID="Image8" runat="server" Height="285px" ImageUrl="~/8.jpg" Width="280px" />
                        <br />
                        <asp:Label ID="Label15" runat="server" Text="26625金币" ForeColor="#660066"></asp:Label>
                        &nbsp;&nbsp;&nbsp;
                        <asp:Button ID="Button22" runat="server" ForeColor="Red" Text="❤" />
                        <asp:Button ID="Button23" runat="server" ForeColor="#67497D" Height="21px" Text="加入购物车" Width="99px" />
                        <br />
                        <br />
                        <asp:Label ID="Label23" runat="server" Text="瑞士欧米茄碟飞系列机械男表" ForeColor="#660066"></asp:Label>
                        <br />
                    </td>
                    <td class="auto-style26">
                        <asp:Image ID="Image11" runat="server" Height="285px" ImageUrl="~/9.jpg" Width="280px" />
                        <br />
                        <asp:Label ID="Label16" runat="server" Text="89金币" ForeColor="#660066"></asp:Label>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <asp:Button ID="Button24" runat="server" ForeColor="Red" Text="❤" />
                        <asp:Button ID="Button25" runat="server" ForeColor="#67497D" Height="21px" Text="加入购物车" Width="99px" />
                        <br />
                        <br />
                        <asp:Label ID="Label24" runat="server" Text="浪莎纯棉百搭复古日系女中筒袜" ForeColor="#660066"></asp:Label>
                        <br />
                    </td>
                </tr>
            </table>
            </div>
           <div class="auto-style34">
           </div>
                        <br />  
              </div>
              <table class="auto-style32">

                  <tr>
                      <td class="auto-style34">
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Label ID="Label25" runat="server" ForeColor="White" Text="非常大牌"></asp:Label>
                          <br />
                          <br />
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Label ID="Label26" runat="server" ForeColor="#CCCCCC" Text="疯抢500积分金币"></asp:Label>
                          <br />
                          <br />
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Image ID="Image12" runat="server" Height="100px" ImageUrl="~/A.jpg" Width="100px" />
                          &nbsp;<asp:Image ID="Image13" runat="server" Height="100px" ImageUrl="~/B.jpg" Width="100px" />
                          <br />
                      </td>
                      <td class="auto-style34">
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Label ID="Label27" runat="server" ForeColor="White" Text="极有家"></asp:Label>
                          <br />
                          <br />
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Label ID="Label28" runat="server" ForeColor="#CCCCCC" Text="精致到一丝不苟的家"></asp:Label>
                          <br />
                          <br />
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Image ID="Image14" runat="server" Height="100px" ImageUrl="~/E.jpg" Width="100px" />
                          &nbsp;<asp:Image ID="Image15" runat="server" Height="100px" ImageUrl="~/D.jpg" Width="100px" />
                      </td>
                      <td class="auto-style34">
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Label ID="Label29" runat="server" ForeColor="White" Text="生活家"></asp:Label>
                          <br />
                          <br />
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Label ID="Label30" runat="server" ForeColor="#CCCCCC" Text="彩色绕线画 陪你看日出"></asp:Label>
                          <br />
                          <br />
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Image ID="Image16" runat="server" Height="100px" ImageUrl="~/I.jpg" Width="100px" />
                          &nbsp;<asp:Image ID="Image17" runat="server" Height="100px" ImageUrl="~/H.jpg" Width="100px" />
                      </td>
                      <td class="auto-style34">
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Label ID="Label31" runat="server" ForeColor="White" Text="汇吃"></asp:Label>
                          <br />
                          <br />
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Label ID="Label32" runat="server" ForeColor="#CCCCCC" Text="高颜值 好品质的食物"></asp:Label>
                          <br />
                          <br />
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Image ID="Image18" runat="server" Height="100px" ImageUrl="~/J.jpg" Width="100px" />
                          &nbsp;<asp:Image ID="Image19" runat="server" Height="100px" ImageUrl="~/F.jpg" Width="100px" />
                      </td>
                      <td class="auto-style34">
                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Label ID="Label33" runat="server" ForeColor="White" Text="苏宁易购"></asp:Label>
                          <br />
                          <br />
                          &nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Label ID="Label34" runat="server" ForeColor="#CCCCCC" Text="1元预约最高抵900金币"></asp:Label>
                          <br />
                          <br />
                          &nbsp;&nbsp;&nbsp;&nbsp;
                          <asp:Image ID="Image20" runat="server" Height="100px" ImageUrl="~/C.jpg" Width="100px" />
                          &nbsp;<asp:Image ID="Image21" runat="server" Height="100px" ImageUrl="~/G.jpg" Width="100px" />
                      </td>
                  </tr>
        </table>
              <p class="auto-style33" style="background-color: #B87442">
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;
                   <br />
                   <br />
                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;
                  <asp:LinkButton ID="LinkButton1" runat="server">金币联盟</asp:LinkButton>
&nbsp;|
                  <asp:LinkButton ID="LinkButton2" runat="server">联系我们</asp:LinkButton>
&nbsp;|
                  <asp:LinkButton ID="LinkButton3" runat="server">意见反馈</asp:LinkButton>
&nbsp;|
                  <asp:LinkButton ID="LinkButton4" runat="server">网站导航</asp:LinkButton>
&nbsp;|
                  <asp:LinkButton ID="LinkButton5" runat="server">帮助中心</asp:LinkButton>
                   <br />
                   <br />
                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;
                  <asp:Label ID="Label35" runat="server" Text="© 2016-2018 粤ICP备06000716号 增值电信业务经营许可证粤B2-20130714 粤公网安备 44010602001077号" ForeColor="#333333"></asp:Label>
        </p>
        </form>
        </body>
</html>
