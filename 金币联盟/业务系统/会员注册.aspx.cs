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
    public partial class 会员注册 : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            SqlConnection con = new SqlConnection("Data Source=.;Database=金币联盟;Uid=sa;Pwd=123;");
            con.Open();
            string str = "select count(*) from Customer where CustomerTel='" + TextBox1.Text.ToString() + "'";
            SqlCommand com = new SqlCommand(str, con);
            int intcont = Convert.ToInt32(com.ExecuteScalar());
            if (intcont > 0)
            {
                Response.Write("alert('对不起!不允许填写相同记录！')");
            }
            else
            {
                try
                {
                    //插入命令 
                    string sqlstr = "insert into Customer (CustomerId,CustomerTel,CustomerPwd,CustomerNewPwd,CustomerName) values(@CustomerId,@CustomerTel,@CustomerPwd,@CustomerNewPwd,@CustomerName)";
                    SqlCommand mycom = new SqlCommand(sqlstr, con);
                    //添加参数 
                    mycom.Parameters.Add(new SqlParameter("@CustomerTel", SqlDbType.VarChar, 50));
                    mycom.Parameters.Add(new SqlParameter("@CustomerPwd", SqlDbType.VarChar, 50));
                    mycom.Parameters.Add(new SqlParameter("@CustomerNewPwd", SqlDbType.VarChar, 50));
                    mycom.Parameters.Add(new SqlParameter("@CustomerName", SqlDbType.VarChar, 50));
                    mycom.Parameters.Add(new SqlParameter("@CustomerId", SqlDbType.VarChar, 50));
                    //给参数赋值 
                    mycom.Parameters["@CustomerTel"].Value = TextBox1.Text;
                    mycom.Parameters["@CustomerPwd"].Value = TextBox2.Text;
                    mycom.Parameters["@CustomerNewPwd"].Value = TextBox3.Text;
                    mycom.Parameters["@CustomerName"].Value = TextBox4.Text;
                    mycom.Parameters["@CustomerId"].Value = TextBox5.Text;
                    //执行添加语句 
                    mycom.ExecuteNonQuery();
                    con.Close();
                    Response.Write("<script language='javascript'>alert('注册成功，请登录！');</script>");

                }
                catch (Exception ex)
                {
                    Response.Write(ex.Message.ToString());
                }
            }
        }

      
    }
}