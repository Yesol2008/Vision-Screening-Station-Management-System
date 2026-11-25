<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ include file="/auth/participantGuard.jsp" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>


<%

String currentPwd = request.getParameter("currentPwd");
String newPwd = request.getParameter("newPwd");
String newPwdConfirm = request.getParameter("newPwdConfirm");

String passwordErr ="";


if ("POST".equalsIgnoreCase(request.getMethod())) {

if (currentPwd == null || currentPwd.trim().isEmpty() || newPwd == null || newPwd.trim().isEmpty()|| newPwdConfirm == null || newPwdConfirm.trim().isEmpty()) {
	passwordErr = "All password fields are required.";
}else if (newPwd.length() < 8 || newPwd.length() > 64) {
	passwordErr = "Password must be 8-64 characters.";
} else if (!newPwd.matches("(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,64}")) {
	passwordErr = "Password must be 8-64 characters and contain at least one uppercase letter, one lowercase letter, one number and one symbol.";
}else if(!newPwdConfirm.equals(newPwd)) {
    passwordErr = "Confirm password doesn't match with new password.";
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

if (passwordErr.isEmpty()) {

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
				 						
				 String update = "UPDATE users SET password = ? WHERE user_id=?";
						 
					try(PreparedStatement ps = conn.prepareStatement(update)){
						String hashedPassword = BCrypt.hashpw(newPwd, BCrypt.gensalt(10));
						ps.setString(1, hashedPassword);
						ps.setInt(2, participantId); 
							
						int rows = ps.executeUpdate();
						if (rows > 0) {
						   response.sendRedirect(request.getContextPath() + "/login.jsp?msg=successUpdate");
						    return;
						}else{
							response.sendRedirect(request.getContextPath() + "myProfile.jsp?errCode=failUpdate");
						    return;
							
						}
							
					}
					 
				 
			 }
		
		}
	}catch (ClassNotFoundException e) {
		System.err.println("JDBC Driver not found"+ e);
		passwordErr = "Unable to connect to the server. Please try again later.";

	} catch (SQLException e) {
		System.err.println("Database error in login.jsp"+ e);
		passwordErr = "Unable to connect to the server. Please try again later.";

	}catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        out.println("Unable to connect to the database.");
    }
}
}
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Update password - Vision Screening</title>
</head>
<body>

<div class="page">
<%@ include file="/shared/header.jsp" %>

	<div class="card">
		<% if (!passwordErr.trim().isEmpty()) { %>
			<div class="fieldError"><%= escapeHtml(passwordErr) %></div>
		<%} %>
		<form method="post">
			<div>
				<label>Current password:</label>
				<input type="password" name="currentPwd">
			</div>
			<div>
				<label>New Password</label>
				<input type="password" name="newPwd">
			</div>
			<div>
				<label>Confirm New Password</label>
				<input type="password" name="newPwdConfirm">
			</div>
			<div>
				<input type="submit" value="Update" class="btn btnPrimary">
				<a class="btn btnPrimary" href="myProfile.jsp">Back</a>
			</div>
			
		</form>
	
	</div>

	<%@ include file="/shared/footer.html" %>

</div>

</body>
</html>