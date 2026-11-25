<%--
Author: Htet Yamin Aung (P2535607)
Date: 25/11/2026
Description: ST0510/JAD Assignment 1 - Staff: list, search and filter participants
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>
<%-- staff only: redirects anyone who is not a logged-in, active staff member --%>
<%@ include file="/auth/staffGuard.jsp" %>
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

	//2. search keyword (optional): an empty box means no search
	String keyword = request.getParameter("keyword");
	if (keyword == null) {
		keyword = "";
	}
	keyword = keyword.trim();

	//3. status filter (optional): only the two known values are accepted, anything else means all
	String status = request.getParameter("status");
	if (!"active".equals(status) && !"inactive".equals(status)) {
		status = "";
	}

	//4. load the participants; each row is stored so the connection can close before the HTML
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

		// Step 4: CallableStatement for the stored procedure; NULL means "don't filter on this"
		CallableStatement cs = conn.prepareCall("{ call view_all_participants(?, ?) }");

		if (keyword.isEmpty()) {
			cs.setNull(1, Types.VARCHAR);
		} else {
			cs.setString(1, keyword);
		}

		if (status.equals("active")) {
			cs.setBoolean(2, true);
		} else if (status.equals("inactive")) {
			cs.setBoolean(2, false);
		} else {
			cs.setNull(2, Types.BOOLEAN);
		}

		// Step 5: Execute query
		ResultSet rs = cs.executeQuery();

		// Step 6: Process result - while, as there can be many rows
		while (rs.next()) {
			Map<String, Object> row = new HashMap<>();
			row.put("participantId", rs.getInt("participant_id"));
			row.put("fullName", rs.getString("full_name"));
			row.put("contactNum", rs.getString("contact_number"));
			row.put("username", rs.getString("username"));
			row.put("isActive", rs.getBoolean("is_active"));
			row.put("eventIds", rs.getString("event_ids"));
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
	<main class="page">
		<%@ include file="/shared/header.jsp" %>

		<div class="titleRow">
			<h1>Participants</h1>
			<a class="btn btnDark" href="addParticipant.jsp">+ Add participant</a>
		</div>
		<p class="intro">Manage participant accounts and view their event sign-ups.</p>

		<%-- search and filter: GET so the choices stay in the URL --%>
		<label class="searchLabel" for="keyword">Search participants</label>
		<form action="listParticipants.jsp" method="get" class="searchBar">
			<input type="text" id="keyword" name="keyword" maxlength="100"
				placeholder="Try Alex, Tan, alex123, or a phone number"
				value="<%= escapeHtml(keyword) %>">
			<select name="status">
				<option value="">All statuses</option>
				<option value="active" <%= "active".equals(status) ? "selected" : "" %>>Active</option>
				<option value="inactive" <%= "inactive".equals(status) ? "selected" : "" %>>Inactive</option>
			</select>
			<button type="submit" class="btn btnPrimary">Search</button>
		</form>

		<div class="card">
			<%-- success / error messages --%>
			<% if (msgText != null) { %>
				<div class="msgBox msgSuccess"><%= msgText %></div>
			<% } %>
			<% if (errMessage != null) { %>
				<div class="msgBox msgError"><%= errMessage %></div>
			<% } %>

			<% if (loadErr) { %>
				<div class="msgBox msgError">Participants could not be loaded. Please try again later.</div>
			<% } else if (participants.isEmpty()) { %>
				<p class="note">No participants found. Try a different keyword or status.</p>
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
		</div>

		<%@ include file="/shared/footer.html" %>
	</main>
</body>
</html>