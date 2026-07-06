using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace 业务系统
{
    public partial class 积金币 : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            SqlConnection conn = new SqlConnection();
            string connectionString = "server=.;database=金币联盟;uid=sa; pwd=123";
            conn.ConnectionString = connectionString;
            conn.Open();
            string sqlStr = "insert into [金币联盟].[dbo].[积分明细表]([积金币兑换码],[积金币商品名称],[积金币数目])  select[积金币兑换码],[积金币商品名称],[积金币数目] from[dbo].[积金币兑换码] where[dbo].[积金币兑换码].[积金币兑换码]=''" + TextBox1.Text.ToString() + "''";
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = conn;
            cmd.CommandText = sqlStr;
            conn.Close();


        }
    }
}