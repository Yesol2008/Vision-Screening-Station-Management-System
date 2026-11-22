<%--
	Yesol's part (placeholder to test the redirect from register.jsp)
	TODO (Yesol): print the registration success message on the login page
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
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

String returnUrl = "login.jsp";
String message = "";
String usernameErr = null;
String passwordErr = null;
String errCode = request.getParameter("errCode");


if ("registered".equals(request.getParameter("msg"))) {
	message = "Account registered successfully. You can now sign in to your account.";
	} 

//for staff verification
if ("sessionExpired".equals(errCode)) {
	message = "Your session has expired. Please sign in again.";
}
else if ("notLoggedIn".equals(errCode)) {
	message = "Please sign in to access this page.";
}
else if ("dbError".equals(errCode)) {
	message = "Unable to connect to the server. Please try again later.";
}
else if ("accountNotFound".equals(errCode)) {
	message = "Your account could not be found. Please contact the administrator.";
}
else if ("accountInactive".equals(errCode)) {
	message = "Your account is inactive. Please contact the administrator.";
}
else if ("notAuthorised".equals(errCode)) {
	message = "You are not authorised to access that page.";
}




String username = request.getParameter("username");
String pwd = request.getParameter("pwd");


if ("POST".equalsIgnoreCase(request.getMethod())) {

	if (username == null || pwd == null) {

		message = "Please enter your username and password.";

	}else {
		
		//username validation
		if (username.isEmpty()) {
            usernameErr = "Username cannot be empty.";
        }

        //password validation
        if (pwd.trim().isEmpty()) {
            passwordErr = "Password cannot be empty.";
        }
        
        if(usernameErr == null && passwordErr == null){

	try {
		// Step 1: Load JDBC Driver
		Class.forName("com.mysql.cj.jdbc.Driver");

		// Step 2: Read database connection details
		Dotenv dotenv = Dotenv.configure()
						.directory(application.getRealPath("/WEB-INF"))
						.load();

		String connURL = dotenv.get("DB_URL");
		String dbUser = dotenv.get("DB_USERNAME");
		String dbPassword = dotenv.get("DB_PASSWORD");
		String sql = "SELECT user_id, password_hash, role, is_active FROM users WHERE username = ?";

		// Step 3: Establish connection
		//using try with statement so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, dbUser, dbPassword);

		// Step 4: Retrieve user information
				
			PreparedStatement ps = conn.prepareStatement(sql)) {

				ps.setString(1, username.trim());

				try (ResultSet rs = ps.executeQuery()){

				if (rs.next()) {
						String hashedPassword = rs.getString("password_hash");

						// Compare passwords
						if (BCrypt.checkpw(pwd, hashedPassword)) {

							// check if account is active
							boolean isActive = rs.getBoolean("is_active");

							if (isActive) {

							int userId = rs.getInt("user_id");
                                    String role = rs.getString("role");

							// Invalidate the previous session to prevent session fixation
								if (request.getSession(false) != null) {
								request.getSession(false).invalidate();
								}
							
							session = request.getSession(true);
								
							// Store user information in session
							session.setAttribute("userId", userId);
							session.setAttribute("role", role);
						
								//Redirect according to user role. it will be replaced when the page is implemented
								if ("staff".equalsIgnoreCase(role)) {
									
									response.sendRedirect("staff/listEvents.jsp");
									return;
								} else if ("participant".equalsIgnoreCase(role)) {
									
									response.sendRedirect("participant/browseEvents.jsp");
									return;
									
								} else {
									session.invalidate();
									message = "Invalid account role. Please contact the administrator.";
								}
						
							} else {
								message = "Your account is inactive. Please contact the administrator.";
							}
						
						//if else for pass
						} else {
						
						message = "Incorrect username or password.";
						
						}
					
					} else {
						message = "Incorrect username or password.";
					}
				}

			
			}


	} catch (Exception e) {

		System.err.println("login.jsp - " + e);
		message = "Something went wrong. Please try again.";
				
	}
	}
	}
}


%>

<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Login - Vision Screening</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
<div class="page">

	<%-- placeholder for now will be replaced by shared header include file --%>
	<div class="topbar">
		<a class="brand" href="index.jsp">
			<img class="logo" src="<%= request.getContextPath() %>/images/logo.png" alt="Vision Screening logo">
			<div>
				<div class="brandName">Vision Screening</div>
				<div class="brandSub">Station Management System</div>
			</div>
		</a>
		<nav class="navMenu">
			<a href="index.jsp">Overview</a>
			<a href="login.jsp" class="active">Sign in</a>
			<a href="register.jsp">Create account</a>
		</nav>
		<div class="userBox">
			<span class="userRole">Guest</span>
		</div>
	</div>


	<div class="card">
		
	<h1 class="pageTitle">Login form</h1>
	<p class="pageSub">Login to your vision screening appointments and results.</p>
		<% if (!message.isEmpty()) { %>
    		<div class="msgBox msgError"><%= message %></div>
		<% } %>	
	<form method="post">
    	<div class="field">
			<label for="username">Username <span class="req">*</span></label>
			<input type="text" id="username" name="username" maxlength="20" placeholder="e.g. alex_tan" 
			value="<%= message != null || username == null ? "" : escapeHtml(username.trim()) %>" 
			class="<%= usernameErr != null ? "inputError" : "" %>">
			<% if (usernameErr != null) { %>
				<div class="fieldError"><%= escapeHtml(usernameErr) %></div>
			<% } %>
			
    	</div>
    	<div class="field">
			<label for="password">password <span class="req">*</span></label>
			<input type="password"  id="password" name="pwd" maxlength="64"
			class="<%= passwordErr != null ? "inputError" : "" %>">
			<% if (passwordErr != null) { %>
				<div class="fieldError"><%= escapeHtml(passwordErr) %></div>
			<% } %>
    	</div>
    	<div class="formActions">
    		<span>Do not have an account yet? <a href="register.jsp">register for an account.</a></span>
    		<input type="submit" class="btn btnPrimary" value="Submit">
    	</div>
	</form>
	</div>

	<jsp:include page="/footer.jsp"/>

</div>


</body>
</html>
