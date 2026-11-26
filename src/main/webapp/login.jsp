<%--
	Yesol's part (placeholder to test the redirect from register.jsp)
	TODO (Yesol): print the registration success message on the login page
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
<%@ page import="io.github.cdimascio.dotenv.DotenvException" %>


<% 
//defining the error messages
String message = "";
String usernameErr = null;
String passwordErr = null;
String errCode = request.getParameter("errCode");
String msg = request.getParameter("msg");
String successMessage ="";

//setting value into the success message string
if ("registered".equals(msg)) {
	successMessage = "Account registered successfully. You can now sign in to your account.";
} else if("successUpdate".equals(msg)){
	successMessage = "Account password updated successfully. Please log in again.";
}else if("loggedOut".equals(msg)){
	successMessage = "Successfully logged out.";
}

//setting the value for error messsage
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



//getting username and password from the login form
String username = request.getParameter("username");
String pwd = request.getParameter("pwd");

//checking if the request method is post. if not, code will not be executed
if ("POST".equalsIgnoreCase(request.getMethod())) {

	//if the whole password and username value is null, it will return the general error message
	if (username == null || pwd == null) {

		message = "Please enter your username and password.";

	}else {
		//if either one of the value is missing, it will only return the error according to the field
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
				
				//checking if there is record, if it returns false, it will send the general error message about incorrect userid/password
				if (rs.next()) {
						String hashedPassword = rs.getString("password_hash");

						// Compare passwords if it's wrong, it will send the general error message about incorrect userid/password
						if (BCrypt.checkpw(pwd, hashedPassword)) {

							// check if account is active
							boolean isActive = rs.getBoolean("is_active");
							
							//if the accoun is active, it will retrieve the userid and the role of the user
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


	} catch (ClassNotFoundException e) {
		System.err.println("JDBC Driver not found"+ e);
	    message = "Unable to connect to the server. Please try again later.";

	} catch (SQLException e) {
		System.err.println("Database error in login.jsp"+ e);
	    message = "Unable to connect to the server. Please try again later.";

	}catch (DotenvException e) {
		System.err.println("Environment configuration error in browseEvents.jsp"+ e);
		message="Something went wrong. Please try again later.";

	}catch (Exception e) {

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

<%@ include file="/shared/header.jsp" %>

	<div class="card">
		
	<h1 class="pageTitle">Login form</h1>
	<p class="pageSub">Login to your vision screening appointments and results.</p>
		<% //printing out the error message or success message
			if (!successMessage.isEmpty()) { %>
    		<div class="msgBox msgSuccess"><%= successMessage %></div>
		<% } %>	
		<% if (!message.isEmpty()) { %>
    		<div class="msgBox msgError"><%= message %></div>
		<% } %>	
	<form method="post">
    	<div class="field">
			<label for="username">Username <span class="req">*</span></label>
			<input type="text" id="username" name="username" maxlength="20" placeholder="e.g. alex_tan" 
			value="<%= message != null || username == null ? "" : escapeHtml(username.trim()) %>" 
			class="<%= usernameErr != null ? "inputError" : "" %>">
			<% //printing error message when field is empty
			if (usernameErr != null) { %>
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

	<%@ include file="shared/footer.html" %>

</div>


</body>
</html>
