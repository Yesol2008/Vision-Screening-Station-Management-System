<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>

<div class="page">
	<h5>ST0510 JAD Assignment 1</h5>
	<p>Vision Screening Station Management System: a Java EE web app for healthcare screening events, built with JSP, JDBC and MySQL on Apache Tomcat. It covers participant registration, participant and event CRUD, secure parameterised queries and HttpSession-based login and access control.</p>
	<footer>Issued by @Yesol @Yamin 2026<span>	<a href="<%= request.getContextPath() %>/confirmReset.jsp?returnUrl=<%= java.net.URLEncoder.encode(request.getRequestURI(), "UTF-8") %>">Reset Data</a></span></footer>
</div>
</body>
</html>