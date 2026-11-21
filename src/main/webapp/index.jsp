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
			<a href="index.jsp"class="active">Overview</a>
			<a href="login.jsp">Sign in</a>
			<a href="register.jsp">Create account</a>
		</nav>
		<div class="userBox">
			<span class="userRole">Guest</span>
		</div>
	</div>

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