<%--
Author: Htet Yamin Aung (P2535607)
Date: 20/11/2026
Description: ST0510/JAD Assignment 1 - Staff: view one participant's details
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>
<%-- fragments kept in WEB-INF so they cannot be opened directly --%>
<%@ include file="/auth/staffGuard.jsp" %>
<%
	//1. the id arrives as text from the hidden field in listParticipants.jsp
	String idText = request.getParameter("id");

	//page opened directly without an id
	if (idText == null) {
		response.sendRedirect("listParticipants.jsp?errCode=invalidId");
		return;
	}

	//id is not a number (e.g. viewParticipant.jsp?id=abc)
	int participantId;
	try {
		participantId = Integer.parseInt(idText.trim());
	} catch (NumberFormatException e) {
		response.sendRedirect("listParticipants.jsp?errCode=invalidId");
		return;
	}

	//2. look the participant up; the id came from the browser, so it goes in through ?
	boolean found = false;
	String fullName = null;
	String username = null;
	String contactNum = null;
	String email = null;
	boolean isActive = false;
	String eventIds = null;
	Connection conn = null;

	try {
		//Load JDBC Driver
		Class.forName("com.mysql.cj.jdbc.Driver");

		//Read connection details from .env in WEB-INF
		Dotenv dotenv = Dotenv.configure().directory(application.getRealPath("/WEB-INF")).load();
		String connURL = dotenv.get("DB_URL");
		String dbUser = dotenv.get("DB_USERNAME");
		String dbPassword = dotenv.get("DB_PASSWORD");

		//Establish connection
		conn = DriverManager.getConnection(connURL, dbUser, dbPassword);

		//PreparedStatement; withdrawn sign-ups are not listed
		String sql = "SELECT p.full_name, p.contact_number, p.email, u.username, u.is_active, "
				+ "GROUP_CONCAT(r.event_id ORDER BY r.event_id) AS event_ids "
				+ "FROM participants p "
				+ "JOIN users u ON p.user_id = u.user_id "
				+ "LEFT JOIN registrations r ON r.participant_id = p.participant_id AND r.status <> 'Withdrawn' "
				+ "WHERE p.participant_id = ? "
				+ "GROUP BY p.participant_id, p.full_name, p.contact_number, p.email, u.username, u.is_active";
		PreparedStatement ps = conn.prepareStatement(sql);
		ps.setInt(1, participantId);

		//Execute query
		ResultSet rs = ps.executeQuery();

		//Process result - if, not while: an id matches one row at most
		if (rs.next()) {
			found = true;
			fullName = rs.getString("full_name");
			username = rs.getString("username");
			contactNum = rs.getString("contact_number");
			email = rs.getString("email");
			isActive = rs.getBoolean("is_active");
			eventIds = rs.getString("event_ids");
		}
	} catch (ClassNotFoundException e) {
		System.err.println("viewParticipant.jsp - driver not found: " + e);
		response.sendRedirect("listParticipants.jsp?errCode=dbError");
		return;
	} catch (SQLException e) {
		System.err.println("viewParticipant.jsp - SQL error: " + e);
		response.sendRedirect("listParticipants.jsp?errCode=dbError");
		return;
	} catch (DotenvException e) {
		System.err.println("viewParticipant.jsp - .env error: " + e);
		response.sendRedirect("listParticipants.jsp?errCode=dbError");
		return;
	} catch (Exception e) {
		System.err.println("viewParticipant.jsp - " + e);
		response.sendRedirect("listParticipants.jsp?errCode=dbError");
		return;
	} finally {
		//Close connection
		if (conn != null) {
			try {
				conn.close();
			} catch (SQLException e) {
				System.err.println("Error closing connection: " + e);
			}
		}
	}

	//3. valid number, but no participant with that id
	if (!found) {
		response.sendRedirect("listParticipants.jsp?errCode=notFound");
		return;
	}

	//4. event ids "1,3" from GROUP_CONCAT become "E01, E03"
	String eventsText = "None";
	if (eventIds != null) {
		String[] parts = eventIds.split(",");
		eventsText = "";
		for (int i = 0; i < parts.length; i++) {
			if (i > 0) {
				eventsText += ", ";
			}
			eventsText += "E" + twoDigits(Integer.parseInt(parts[i]));
		}
	}
%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Participant details - Vision Screening</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
	<main class="page">
		<%@ include file="/shared/header.jsp" %>

		<div class="card">
			<h1 class="pageTitle">Participant details</h1>

			<div class="detailRow">
				<span class="detailLabel">Participant ID</span>
				<span>P<%= twoDigits(participantId) %></span>
			</div>
			<div class="detailRow">
				<span class="detailLabel">Name</span>
				<span><%= escapeHtml(fullName) %></span>
			</div>
			<div class="detailRow">
				<span class="detailLabel">Username</span>
				<span><%= escapeHtml(username) %></span>
			</div>
			<div class="detailRow">
				<span class="detailLabel">Phone</span>
				<span><%= escapeHtml(contactNum) %></span>
			</div>
			<div class="detailRow">
				<span class="detailLabel">Email</span>
				<span><%= escapeHtml(email) %></span>
			</div>
			<div class="detailRow">
				<span class="detailLabel">Status</span>
				<span><%= isActive ? "Active" : "Inactive" %></span>
			</div>
			<div class="detailRow">
				<span class="detailLabel">Registered events</span>
				<span><%= eventsText %></span>
			</div>

			<div class="formActions">
				<a class="btn" href="listParticipants.jsp">Back</a>
				<%-- the id is passed on to the edit page in a hidden field --%>
				<form action="editParticipant.jsp" method="get">
					<input type="hidden" name="id" value="<%= participantId %>">
					<button type="submit" class="btn btnDark">Edit participant</button>
				</form>
			</div>
		</div>
		<%@ include file="/shared/footer.html" %>
	</main>

</body>
</html>