<%--
Author: Htet Yamin Aung (P2535607)
Date: 20/11/2026
Description: ST0510/JAD Assignment 1 - Staff: list and search participants
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>
<%-- staff only: redirects anyone who is not a logged-in, active staff member --%>
<%@ include file="/WEB-INF/auth/staffGuard.jsp" %>
<%
	//1. match known msg / errCode values to a message; raw values are never printed
	String msg = request.getParameter("msg");
	String errCode = request.getParameter("errCode");
	String msgText = null;
	String errMessage = null;

	if (msg != null) {
		if (msg.equals("deactivated")) {
			msgText = "The participant account has been deactivated.";
		} else if (msg.equals("added")) {
			msgText = "The participant has been added.";
		} else if (msg.equals("updated")) {
			msgText = "The participant details have been updated.";
		}
	}

	if (errCode != null) {
		if (errCode.equals("invalidId")) {
			errMessage = "Invalid participant id.";
		} else if (errCode.equals("notFound")) {
			errMessage = "Participant not found.";
		} else if (errCode.equals("dbError")) {
			errMessage = "Something went wrong. Please try again later.";
		} else if (errCode.equals("notAuthorised")) {
			errMessage = "You don't have access to that page.";
		} else if (errCode.equals("hasSignups")) {
			errMessage = "This participant has event sign-ups and cannot be deactivated.";
		} else if (errCode.equals("alreadyInactive")) {
			errMessage = "This participant is already inactive.";
		} else if (errCode.equals("invalidRequest")) {
			errMessage = "This page can't be opened directly. Please select a participant from the list below.";
		}
	}

	//2. search keyword from the search box (optional)
	String keyword = request.getParameter("keyword");
	if (keyword == null) {
		keyword = "";
	}
	keyword = keyword.trim();

	//3. load the participants; each row is stored so the connection can close before the HTML
	List<Map<String, Object>> participants = new ArrayList<>();
	boolean loadErr = false;
	Connection conn = null;

	try {
		// Step 1: Load JDBC Driver
		Class.forName("com.mysql.cj.jdbc.Driver");

		// Step 2: Read connection details from .env in WEB-INF
		Dotenv dotenv = Dotenv.configure().directory(application.getRealPath("/WEB-INF")).load();
		String connURL = dotenv.get("DB_URL");
		String dbUser = dotenv.get("DB_USERNAME");
		String dbPassword = dotenv.get("DB_PASSWORD");

		// Step 3: Establish connection
		conn = DriverManager.getConnection(connURL, dbUser, dbPassword);

		// Step 4: PreparedStatement; withdrawn sign-ups are not counted
		String sql = "SELECT p.participant_id, p.full_name, p.contact_number, u.username, u.is_active, "
				+ "GROUP_CONCAT(r.event_id ORDER BY r.event_id) AS event_ids, "
				+ "COUNT(r.event_id) AS signup_count "
				+ "FROM participants p "
				+ "JOIN users u ON p.user_id = u.user_id "
				+ "LEFT JOIN registrations r ON r.participant_id = p.participant_id AND r.status <> 'Withdrawn' "
				+ "WHERE p.full_name LIKE ? OR u.username LIKE ? OR p.contact_number LIKE ? "
				+ "GROUP BY p.participant_id, p.full_name, p.contact_number, u.username, u.is_active "
				+ "ORDER BY p.participant_id";
		PreparedStatement ps = conn.prepareStatement(sql);

		//an empty keyword gives %% which matches every row
		String pattern = "%" + keyword + "%";
		ps.setString(1, pattern);
		ps.setString(2, pattern);
		ps.setString(3, pattern);

		// Step 5: Execute query
		ResultSet rs = ps.executeQuery();

		// Step 6: Process result - while, as there can be many rows
		while (rs.next()) {
			Map<String, Object> row = new HashMap<>();
			row.put("participantId", rs.getInt("participant_id"));
			row.put("fullName", rs.getString("full_name"));
			row.put("contactNum", rs.getString("contact_number"));
			row.put("username", rs.getString("username"));
			row.put("isActive", rs.getBoolean("is_active"));
			row.put("eventIds", rs.getString("event_ids"));
			row.put("signupCount", rs.getInt("signup_count"));
			participants.add(row);
		}
	} catch (ClassNotFoundException e) {
		System.err.println("listParticipants.jsp - driver not found: " + e);
		loadErr = true;
	} catch (SQLException e) {
		System.err.println("listParticipants.jsp - SQL error: " + e);
		loadErr = true;
	} catch (DotenvException e) {
		System.err.println("listParticipants.jsp - .env error: " + e);
		loadErr = true;
	} catch (Exception e) {
		System.err.println("listParticipants.jsp - " + e);
		loadErr = true;
	} finally {
		// Step 7: Close connection
		if (conn != null) {
			try {
				conn.close();
			} catch (SQLException e) {
				System.err.println("Error closing connection: " + e);
			}
		}
	}
%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Participants - Vision Screening</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
	
	<%-- TODO: shared signed-in header (brand, user box, log out) --%>
	<%-- TODO: staff nav (Overview, Participants, Events) with Participants active --%>

	<main class="page">
	<%@ include file="/WEB-INF/shared/header.jsp" %>
		<div class="titleRow">
			<h1>Participants</h1>
			<a class="btn btnDark" href="addParticipant.jsp">+ Add participant</a>
		</div>
		<p class="intro">Manage participant accounts and view their event sign-ups.</p>

		<%-- success / error messages --%>
		<% if (msgText != null) { %>
			<div class="msgBox msgSuccess"><%= msgText %></div>
		<% } %>
		<% if (errMessage != null) { %>
			<div class="msgBox msgError"><%= errMessage %></div>
		<% } %>

		<%-- search: GET so the keyword stays in the URL --%>
		<form action="listParticipants.jsp" method="get">
			<label class="searchLabel" for="keyword">Search participants</label>
			<div class="searchRow">
				<input type="text" id="keyword" name="keyword" maxlength="100"
					placeholder="Try Alex, Tan, U01, or a phone number"
					value="<%= escapeHtml(keyword) %>">
				<button type="submit" class="btn">Search</button>
				<% if (!keyword.isEmpty()) { %>
					<a class="btn" href="listParticipants.jsp">Clear</a>
				<% } %>
			</div>
		</form>

		<% if (loadErr) { %>
			<div class="msgBox msgError">Participants could not be loaded. Please try again later.</div>
		<% } else if (participants.isEmpty()) { %>
			<p class="note">No participants found.</p>
		<% } else { %>
			<table class="dataTable">
				<thead>
					<tr>
						<th>Participant</th>
						<th>Contact</th>
						<th>Event sign-ups</th>
						<th>Status</th>
						<th>Actions</th>
					</tr>
				</thead>
				<tbody>
				<% for (Map<String, Object> row : participants) {
					int participantId = (Integer) row.get("participantId");
					boolean isActive = (Boolean) row.get("isActive");
					int signupCount = (Integer) row.get("signupCount");
					String eventIds = (String) row.get("eventIds");
				%>
					<tr>
						<td>
							<%= escapeHtml((String) row.get("fullName")) %>
							<div class="small">P<%= twoDigits(participantId) %> · <%= escapeHtml((String) row.get("username")) %></div>
						</td>
						<td><%= escapeHtml((String) row.get("contactNum")) %></td>
						<td>
							<%-- event_ids is "1,3" from GROUP_CONCAT, shown as E01 / E03 --%>
							<% if (eventIds == null) { %>
								<span class="small">None</span>
							<% } else {
								for (String eventId : eventIds.split(",")) { %>
									<div>E<%= twoDigits(Integer.parseInt(eventId)) %></div>
							<%	}
							} %>
						</td>
						<td>
							<% if (isActive) { %>
								<span class="badge">Active</span>
							<% } else { %>
								<span class="badge badgeInactive">Inactive</span>
							<% } %>
						</td>
						<td>
							<div class="actions">
							<%-- the id is embedded in a hidden field and sent to the next page --%>
							<form action="viewParticipant.jsp" method="get">
								<input type="hidden" name="id" value="<%= participantId %>">
								<button type="submit" class="btn">View</button>
							</form>
							<form action="editParticipant.jsp" method="get">
								<input type="hidden" name="id" value="<%= participantId %>">
								<button type="submit" class="btn">Edit</button>
							</form>
							<%-- shown for every active participant; confirmDeactivate.jsp checks sign-ups --%>
							<% if (isActive) { %>
								<form action="confirmDeactivate.jsp" method="post">
									<input type="hidden" name="id" value="<%= participantId %>">
									<button type="submit" class="btn">Deactivate</button>
								</form>
							<% } %>
							</div>
						</td>
					</tr>
				<% } %>
				</tbody>
			</table>
		<% } %>
	</main>

	<%-- TODO: shared footer --%>
</body>
</html>
