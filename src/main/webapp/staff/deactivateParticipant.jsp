<%--
Author: Htet Yamin Aung (P2535607)
Date: 22/11/2026
Description: ST0510/JAD Assignment 1 - Staff: deactivate a participant account
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>

<%@ include file="/auth/staffGuard.jsp" %>
<%
	//1. only reachable from the confirmation page, which submits by POST
	if (!"POST".equals(request.getMethod())) {
		response.sendRedirect("listParticipants.jsp?errCode=invalidRequest");
		return;
	}

	//2. the id arrives as text from the hidden field in confirmParticipantDeactivate.jsp
	String idText = request.getParameter("id");

	if (idText == null) {
		response.sendRedirect("listParticipants.jsp?errCode=invalidId");
		return;
	}

	int participantId;
	try {
		participantId = Integer.parseInt(idText.trim());
	} catch (NumberFormatException e) {
		response.sendRedirect("listParticipants.jsp?errCode=invalidId");
		return;
	}

	//3. check the rules again (the request may not come from the button), then update
	String result = null;
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

		//  PreparedStatement to look up the account and its active sign-ups
		String checkSql = "SELECT u.user_id, u.is_active, COUNT(r.event_id) AS signup_count "
				+ "FROM participants p "
				+ "JOIN users u ON p.user_id = u.user_id "
				+ "LEFT JOIN registrations r ON r.participant_id = p.participant_id AND r.status <> 'Withdrawn' "
				+ "WHERE p.participant_id = ? "
				+ "GROUP BY u.user_id, u.is_active";
		PreparedStatement checkPs = conn.prepareStatement(checkSql);
		checkPs.setInt(1, participantId);

		// Execute query
		ResultSet rs = checkPs.executeQuery();

		//  Process result :we will use if instead of while
		//because it will return one row at most
		if (!rs.next()) {
			result = "errCode=notFound";
		} else if (!rs.getBoolean("is_active")) {
			result = "errCode=alreadyInactive";
		} else if (rs.getInt("signup_count") > 0) {
			result = "errCode=hasSignups";
		} else {
			// PreparedStatement to deactivate; is_active is kept only in users
			int userId = rs.getInt("user_id");
			PreparedStatement ps = conn.prepareStatement("UPDATE users SET is_active = FALSE WHERE user_id = ?");
			ps.setInt(1, userId);

			// Execute update - returns the number of rows changed
			int rows = ps.executeUpdate();

			//  Process result
			if (rows == 1) {
				result = "msg=deactivated";
			} else {
				result = "errCode=notFound";
			}
		}
	} catch (ClassNotFoundException e) {
		System.err.println("deactivateParticipant.jsp - driver not found: " + e);
		result = "errCode=dbError";
	} catch (SQLException e) {
		System.err.println("deactivateParticipant.jsp - SQL error: " + e);
		result = "errCode=dbError";
	} catch (DotenvException e) {
		System.err.println("deactivateParticipant.jsp - .env error: " + e);
		result = "errCode=dbError";
	} catch (Exception e) {
		System.err.println("deactivateParticipant.jsp - " + e);
		result = "errCode=dbError";
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

	//4. back to the list with a success or error message (Post/Redirect/Get)
	response.sendRedirect("listParticipants.jsp?" + result);
%>
