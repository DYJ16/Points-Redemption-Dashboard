using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace 业务系统
{
    public partial class 会员登录 : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void TextBox1_TextChanged(object sender, EventArgs e)
        {

        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            string str = "server=.;database=金币联盟;integrated security=true";
            SqlConnection sqlcon = new SqlConnection();
            sqlcon.ConnectionString = str;
            SqlCommand sqlcmd = new SqlCommand();
            sqlcmd.Connection = sqlcon;
            sqlcmd.CommandText = "select *from Customer where CustomerTel='" + this.TextBox1.Text + "' and CustomerPwd='" + this.TextBox2.Text + "'";
            sqlcon.Open();
            SqlDataReader reader = sqlcmd.ExecuteReader();
            if (reader.Read())
            {
                this.Response.Redirect("首页.aspx");
            }
            else
            {
                this.Label4.Text="登陆失败";
            }
            reader.Close();
            sqlcon.Close();

        }
    }
}