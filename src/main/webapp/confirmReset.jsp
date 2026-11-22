<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
    
 <%
 
	String returnUrl = request.getParameter("returnUrl");

 	if (returnUrl == null || returnUrl.isEmpty()) {
		returnUrl = "login.jsp";
	}
 	
 	if(returnUrl.equals("browseEvents.jsp") || returnUrl.equals("registeredEvents.jsp")){
 		returnUrl = "/participant"+returnUrl;
 	}
 	
 %>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Reset Data</title>
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
			<a href="login.jsp">Sign in</a>
			<a href="register.jsp">Create account</a>
		</nav>
		<div class="userBox">
			<span class="userRole">Guest</span>
		</div>
	</div>
	
		<div class="card">
		
			<h1>Reset Demo?</h1>
			<p>This restores sample records and removes accounts and changes made in this tab.</p>
			<a href="${pageContext.request.contextPath}/test/seed.jsp?returnUrl=<%=returnUrl %>" class="btn btnPrimary">
    			Reset Data
			</a>
			<a href="<%=returnUrl %>" class="btn btnPrimary">Cancel</a>
			
		
		</div>
	
	</div>

</body>
</html>