<%--
Author: Htet Yamin Aung (P2535607)
Date: 20/11/2026
Description: ST0510/JAD Assignment 1 - Shared header file
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv , io.github.cdimascio.dotenv.DotenvException" %>
<%@ include file="helpers.jsp" %>
<%
	//base URL excluding the file names
	String base = request.getContextPath();

	//current page's path, e.g. "/staff/listParticipants.jsp"; used to underline the matching tab
	String path = request.getServletPath();

	//header-only names, so they don't clash with the guard's current... variables
	String headerName = null;
	String headerUsername = null;
	String headerRole = null;

	//1. read the logged-in user's id from the session
	// null = not logged in (never logged in, session expired, or logged out)
	Integer headerUserId = (Integer) session.getAttribute("userId");

	//2. otherwise look the user up; a deactivated or deleted account also gets the guest header
	if (headerUserId != null) {
		Connection headerConn = null; //headerConn declared outside try so catch can use it
		try {
			//Load JDBC Driver
			Class.forName("com.mysql.cj.jdbc.Driver");

			//Read connection details from .env in WEB-INF
			Dotenv headerEnv = Dotenv.configure().directory(application.getRealPath("/WEB-INF")).load();

			//Establish connection to MySQL using the values from .env
			headerConn = DriverManager.getConnection(headerEnv.get("DB_URL"),
					headerEnv.get("DB_USERNAME"), headerEnv.get("DB_PASSWORD"));

			//PreparedStatement; LEFT JOIN to keep staff who have no participants row
			PreparedStatement headerPs = headerConn.prepareStatement(
					"SELECT u.username, u.role, p.full_name FROM users u "
					+ "LEFT JOIN participants p ON p.user_id = u.user_id "
					+ "WHERE u.user_id = ? AND u.is_active = TRUE");
			headerPs.setInt(1, headerUserId);

			//Execute query
			ResultSet headerRs = headerPs.executeQuery();

			//Process result - participants show their full name, staff their username
			if (headerRs.next()) {
				headerUsername = headerRs.getString("username");
				headerRole = headerRs.getString("role");
				headerName = headerRs.getString("full_name");
				if (headerName == null) {
					headerName = headerUsername;
				}
			}
		} catch (ClassNotFoundException e) {
			System.err.println("header.jsp - driver not found: " + e);
		} catch (SQLException e) {
			System.err.println("header.jsp - SQL error: " + e);
		} catch (DotenvException e) {
			System.err.println("header.jsp - .env error: " + e);
		} catch (Exception e) {
			//any other error: log it; the page still shows, with the guest header
			System.err.println("header.jsp - " + e);
		} finally {
			//Close connection
			if (headerConn != null) {
				try {
					headerConn.close();
				} catch (SQLException e) {
					System.err.println("Error closing connection: " + e);
				}
			}
		}
	}

	//guest header unless an active user was found above
	boolean signedIn = (headerUsername != null);
	boolean isStaff = "STAFF".equals(headerRole);
%>
<div class="topbar">
	<a class="brand" href="<%= base %>/index.jsp">
		<img class="logo" src="<%= base %>/images/logo.png" alt="Vision Screening logo">
		<span class="brandText">
			<span class="brandName">Vision Screening</span>
			<span class="brandSub">Station Management System</span>
		</span>
	</a>

	<%-- guest menu (shown on the same row as the brand); current page's link is underlined using class "active" --%>
	<% if (!signedIn) { %>
		<nav class="navMenu">
			<a href="<%= base %>/index.jsp" class="<%= path.equals("/index.jsp") ? "active" : "" %>">Overview</a>
			<a href="<%= base %>/login.jsp" class="<%= path.equals("/login.jsp") ? "active" : "" %>">Sign in</a>
			<a href="<%= base %>/register.jsp" class="<%= path.equals("/register.jsp") ? "active" : "" %>">Create account</a>
		</nav>
	<% } %>

	<%--right side of the top bar --%>
	<div class="userBox">
	<% if (!signedIn) { %>
		<span class="userRole">Guest</span>
	<% } else { %>
		<%--group the name and role for CSS to stack them --%>
		<div class="userInfo">
			<%--For line 1, print the full name for Participants and username for Staff--%>
			<span class="userName"><%= escapeHtml(headerName) %></span>
			<% if (isStaff) { %>
				<span class="userRole">Staff</span>
			<% } else { %>
				<span class="userRole"><%= escapeHtml(headerUsername) %> · Participant</span>
			<% } %>
		</div>
		<a class="btn" href="<%= base %>/logout.jsp">Log out</a>
	<% } %>
	</div>
</div>

<%-- signed in menu under the topbar (styled by .topbar + .navMenu) --%>
<% if (signedIn) { %>
	<nav class="navMenu">
		<a href="<%= base %>/index.jsp" class="<%= path.equals("/index.jsp") ? "active" : "" %>">Overview</a>
		<% if (isStaff) { %>
			<a href="<%= base %>/staff/listParticipants.jsp" class="<%= path.equals("/staff/listParticipants.jsp") ? "active" : "" %>">Participants</a>
			<a href="<%= base %>/staff/listEvents.jsp" class="<%= path.equals("/staff/listEvents.jsp") ? "active" : "" %>">Events</a>
		<% } else { %>
			<a href="<%= base %>/participant/browseEvents.jsp" class="<%= path.equals("/participant/browseEvents.jsp") ? "active" : "" %>">Browse events</a>
			<a href="<%= base %>/participant/mySignups.jsp" class="<%= path.equals("/participant/mySignups.jsp") ? "active" : "" %>">My sign-ups</a>
			<a href="<%= base %>/participant/myProfile.jsp" class="<%= path.equals("/participant/myProfile.jsp") ? "active" : "" %>">My profile</a>
		<% } %>
	</nav>
<% } %>