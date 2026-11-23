<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ include file="/WEB-INF/auth/participantGuard.jsp" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>

<%!
private String escapeHtml(String input) {
    if (input == null) {
        return "";
    }

    return input.replace("&", "&amp;")
                .replace("<", "&lt;")
             	.replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
}
%>

<%

String currentPwd = request.getParameter("currentPwd");
String newPwd = request.getParameter("newPwd");
String newPwdConfirm = request.getParameter("newPwdConfirm");

String passwordErr ="";

if (newPwd.trim().isEmpty()) {
	passwordErr = "Password cannot be empty.";
} else if (newPwd.length() < 8 || newPwd.length() > 64) {
	passwordErr = "Password must be 8-64 characters.";
} else if (!newPwd.matches("(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,64}")) {
	passwordErr = "Password must be 8-64 characters and contain at least one uppercase letter, one lowercase letter, one number and one symbol.";
}

Integer participantId = (Integer) session.getAttribute("userId");


if (participantId != null) {

		if (participantId <= 0) {
			//gonna change it later
			response.sendRedirect("myProfile.jsp?errCode=Invalid");
			return;
		}
		

} else {
	response.sendRedirect("myProfile.jsp?errCode=Invalid");
	return;
}
try {
	
	// Step 1: Load environment variables
	Dotenv dotenv =  Dotenv.configure()
	        .directory(application.getRealPath("/WEB-INF"))
	        .load();;

	String connURL = dotenv.get("DB_URL");
	String username = dotenv.get("DB_USERNAME");
	String password = dotenv.get("DB_PASSWORD");
	boolean pwdMatch=false;

    // Step 2: Load JDBC Driver (optional for newer drivers)
    Class.forName("com.mysql.cj.jdbc.Driver");    

	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password)){
			 String sql = "SELECT password FROM users WHERE user_id =?";
			 
			 try(PreparedStatement ps = conn.prepareStatement(sql)){
				 
				 ps.setInt(1,participantId);
				 
				 try(ResultSet rs = ps.executeQuery()){
					 
					if(rs.next()){
						 
						 if(BCrypt.checkpw(currentPwd, rs.getString("password"))){
							 pwdMatch = true;
							 
						 }else{
							 
							 passwordErr = "Wrong password";

						 }
						 
					 }else{
						 
						 response.sendRedirect("myProfile.jsp?errCode=noResult");
						 
					 }
					 
					 
				 }
				 
				 
				 
			 }
			 
			 
			 if(pwdMatch){
				 
				 if(newPwdConfirm.equals(newPwd)){
						
					 String update = "UPDATE users SET password = ? WHERE user_id=?";
							 
						try(PreparedStatement ps = conn.prepareStatement(update)){
							
							ps.setString(1, newPwd);
							ps.setInt(2, participantId); 
							
							ps.executeUpdate();
							
							response.sendRedirect("/login.jsp?msg=successUpdate");
							
						}
					 
				 }else{
					 passwordErr = "Confirm password doesn't match with new password.";
					 
				 }
			 }
		
		}
	}catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        out.println("Unable to connect to the database.");
    }

%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>

<div>
	<div>
	
		
	
	</div>


</div>

</body>
</html>