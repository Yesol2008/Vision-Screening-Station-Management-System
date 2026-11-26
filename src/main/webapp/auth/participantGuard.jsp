<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="io.github.cdimascio.dotenv.DotenvException" %>

<%--
	Author: Htet Yamin Aung (P2535607)
	Description: ST0510/JAD Assignment 1 - session guard for participant pages

	Usage (participant pages only): <%@ include file="/auth/participantGuard.jsp" %>  (before any HTML)
	Only userId is in the session; username, role, active status and participant
	details are read from the database on every request.
	Sets: currentUserId, currentParticipantId, currentUsername, currentName, currentRole
--%>

<%
	// ===== Session guard for participant-related pages =====

	//capture userId from session 
	Integer currentUserId = (Integer) session.getAttribute("userId"); //getAttribute returns an Object so typecast to Integer(can be null)

	//Redirect unauthenticated users to the login page (expired session or no login)
	if (currentUserId == null) {
		//session ID received but not valid/expired
		if (request.getRequestedSessionId() != null && !request.isRequestedSessionIdValid()) {
			response.sendRedirect(request.getContextPath() + "/login.jsp?errCode=sessionExpired");
		} else {
			//no session ID (not logged in)
			response.sendRedirect(request.getContextPath() + "/login.jsp?errCode=notLoggedIn");
		}
		return;
	}

	boolean accountFound = false;

	int currentParticipantId = 0;
	String currentUsername = null;
	String currentName = null;
	String currentRole = null;
	boolean currentActive = false;

	Connection guardConn = null;

	try {
		//Load the JDBC driver
		Class.forName("com.mysql.cj.jdbc.Driver");

		//Read the database connection details from WEB-INF/.env
		Dotenv guardEnv = Dotenv.configure()
				.directory(application.getRealPath("/WEB-INF")).load();

		//Connect to the database
		guardConn = DriverManager.getConnection(guardEnv.get("DB_URL"),
				guardEnv.get("DB_USERNAME"), guardEnv.get("DB_PASSWORD"));

		//Prepared statement to select the account and participant details using the userId
		//LEFT JOIN: a staff account has no participants row, but is still found,
		//so the role check below can send staff to their own pages
		PreparedStatement guardPs = guardConn.prepareStatement(
				"SELECT u.username, u.role, u.is_active, p.participant_id, p.full_name "
				+ "FROM users u LEFT JOIN participants p ON p.user_id = u.user_id "
				+ "WHERE u.user_id = ?");
		guardPs.setInt(1, currentUserId);

		ResultSet guardRs = guardPs.executeQuery();

		//one row at most so use if instead of while
		if (guardRs.next()) {
			accountFound = true;
			currentUsername = guardRs.getString("username");
			currentRole = guardRs.getString("role");
			currentActive = guardRs.getBoolean("is_active");
			currentParticipantId = guardRs.getInt("participant_id");   //0 if no participants row

			//participants show their full name in the header
			currentName = guardRs.getString("full_name");
		}
		//Catch errors: print details to the console for debugging,
		//but redirect the user to the login page with a general error message
	} catch (ClassNotFoundException e) {
		//JDBC driver not found
		System.err.println("Error loading JDBC driver :" + e);
		response.sendRedirect(request.getContextPath() + "/login.jsp?errCode=dbError");
		return;
	} catch (SQLException e) {
		//Database connection or query failed
		System.err.println("Error accessing database :" + e);
		response.sendRedirect(request.getContextPath() + "/login.jsp?errCode=dbError");
		return;
	} catch (DotenvException e) {
		//.env file missing or unreadable
		System.err.println("Error loading .env file :" + e);
		response.sendRedirect(request.getContextPath() + "/login.jsp?errCode=dbError");
		return;
	} catch (Exception e) {
		//Any other unexpected error
		System.err.println("Unexpected error in participant guard :" + e);
		response.sendRedirect(request.getContextPath() + "/login.jsp?errCode=dbError");
		return;
	} finally {
		//close the connection
		if (guardConn != null) {
			try {
				guardConn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
	}

	// Account no longer exists 
	if (!accountFound) {
		session.invalidate();
		response.sendRedirect(request.getContextPath() + "/login.jsp?errCode=accountNotFound");
		return;
	}

	// Account exists but has been deactivated.
	if (!currentActive) {
		session.invalidate();
		response.sendRedirect(request.getContextPath() + "/login.jsp?errCode=accountInactive");
		return;
	}

	// only participants may access pages in the participant folder
	if (!"PARTICIPANT".equals(currentRole)) {
		response.sendRedirect(request.getContextPath() + "/staff/listParticipants.jsp?errCode=notAuthorised");
		return;
	}
%>