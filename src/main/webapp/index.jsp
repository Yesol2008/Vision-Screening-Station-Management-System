<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Vision Screening Management System-Overview</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>

<div class="page">

<%@ include file="/WEB-INF/shared/header.jsp" %>


	<div class="card">
		<h1> Vision Screening Management System</h1>
		
		<div>
			<h3>Get started with your Vision-Screening</h3>
			<p>gonna fill up the context later</p>
			<a href="login.jsp" class="btn btnPrimary">Login</a>
		
		</div>
		<div class="section">
			<h3>Participant</h3>
			<p>Update your own profile, sign up for multiple events and manage your commitments.</p>
		</div>
		<div class="section">
			<h3>Staffs</h3>
			<p>Create and manage events, administer screening participants and view participant sign-ups.</p>
		</div>
		<div class="section">
			<h3>Create participant account</h3>
			<p>Participants can register themselves or use pre-populated accounts. Staff accounts are pre-populated.</p>
			<a href="register.jsp">Create an account</a>
		</div>
	
	</div>



	<jsp:include page="/footer.jsp"/>


</div>

</body>
</html>