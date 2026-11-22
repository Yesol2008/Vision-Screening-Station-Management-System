<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@page import="io.github.cdimascio.dotenv.Dotenv"%>
<%@page import ="java.sql.*"%>
<%@page import = "org.mindrot.jbcrypt.BCrypt"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>

<%

// password for each users
// "admuser", "Staff@123"
// "john123" "Participant@123"
// "mary123" "Participant@456"
// "alex123" "Participant@789"
// "sarah123" "Participant@000"





%>

<%
	try {
		
		// Step 1: Load environment variables
		Dotenv dotenv =  Dotenv.configure()
		        .directory(application.getRealPath("/WEB-INF"))
		        .load();;

		String connURL = dotenv.get("DB_URL");
		String username = dotenv.get("DB_USERNAME");
		String password = dotenv.get("DB_PASSWORD");
		
		out.println("DB URL: " + connURL);
		out.println("Username: " + username);
		out.println("Password loaded: " + (password != null));
		
		// Get the return URL
	    String returnUrl = request.getParameter("returnUrl");

	    if (returnUrl == null || returnUrl.isEmpty()) {
	        returnUrl = "login.jsp";
	    }
	    
	    ///dk
	    if(returnUrl == "browseEvents.jsp" || returnUrl =="registeredEvents.jsp"){
	 		returnUrl = "/participant"+returnUrl;
	 	}

        // Step 2: Load JDBC Driver (optional for newer drivers)
        Class.forName("com.mysql.cj.jdbc.Driver");
        		
		
        	// Step 3: Establish database connection. Used try-with so that connection will close automatically
			Connection conn = DriverManager.getConnection(connURL, username, password);
			out.println("Database connected successfully!");

		
			// Step 4: Create Statement object
			Statement stmt = conn.createStatement();
			
			
			
			//reset db
			stmt.execute("SET FOREIGN_KEY_CHECKS = 0");

			stmt.executeUpdate("TRUNCATE TABLE registrations");
			stmt.executeUpdate("TRUNCATE TABLE participants");
			stmt.executeUpdate("TRUNCATE TABLE events");
			stmt.executeUpdate("TRUNCATE TABLE users");

			stmt.execute("SET FOREIGN_KEY_CHECKS = 1");
			
					
					//for users
					 String[] usernames = {
								"admuser",
								"john123",
								"mary123",
								"alex123",
								"sarah123",
								"david123",
								"emma123",
								"james123",
								"lisa123",
								"daniel123",
								"sophia123"
					        };

					        String[] passwords = {
					        	"Staff@123",
					        	"Participant@123",
					       		"Participant@456",
					    		"Participant@789",
								"Participant@000",
					  			"Participant@111",
					  			"Participant@222",
								"Participant@333",
								"Participant@444",
								"Participant@555",
								"Participant@666"
					        };

					        String[] roles = {
					            "STAFF",
					            "PARTICIPANT",
					            "PARTICIPANT",
					            "PARTICIPANT",
					            "PARTICIPANT",
					            "PARTICIPANT",
					            "PARTICIPANT",
					            "PARTICIPANT",
					            "PARTICIPANT",
					            "PARTICIPANT",
					            "PARTICIPANT"
					        };
					        
					String sql = "INSERT INTO users "
					              + "(username, password_hash, role) "
					              + "VALUES (?, ?, ?)";
				    
					PreparedStatement pstmt = conn.prepareStatement(sql);

			        for (int i = 0; i < usernames.length; i++) {

			            String hashedPassword = BCrypt.hashpw(
			                passwords[i],
			                BCrypt.gensalt(10)
			            );

			            pstmt.setString(1, usernames[i]);
			            pstmt.setString(2, hashedPassword);
			            pstmt.setString(3, roles[i]);

			            pstmt.executeUpdate();
			        }

			 //inserting in participants
			 
			String insertParticipants =
    			"INSERT INTO participants "
    			+ "(user_id, full_name, email, contact_number) "
    			+ "VALUES "
 				+ "(2, 'John Tan', 'john@gmail.com', '91234567'), "
 				+ "(3, 'Mary Lim','mary@gmail.com', '92345678'), "
   				+ "(4, 'Alex Wong', 'alex@gmail.com', '93456789'), "
				+ "(5, 'Sarah Lee', 'sarah@gmail.com', '94567890'), "
				+ "(6, 'David Tan', 'david@gmail.com', '95678901'), "
				+ "(7, 'Emma Chua', 'emma@gmail.com', '96789012'), "
  				+ "(8, 'James Koh', 'james@gmail.com', '97890123'), "
    			+ "(9, 'Lisa Ng', 'lisa@gmail.com', '98901234'), "
				+ "(10, 'Daniel Goh', 'daniel@gmail.com', '89012345'), "
    			+ "(11, 'Sophia Lim', 'sophia@gmail.com', '90123456')";

			stmt.executeUpdate(insertParticipants);
			
			//inserting event
			
			String insertEvents =
    		"INSERT INTO events "
   				+ "(event_name, event_date, location, status) "
    			+ "VALUES "
			    + "('Vision Screening Day', '2026-12-05', 'East Coast Park', 'Upcoming'), "
    			+ "('Eye Health Screening', '2026-12-15', 'Marina Bay', 'Upcoming'), "
    			+ "('Community Vision Screening', '2026-11-10', 'Singapore Polytechnic', 'Completed'), "
    			+ "('Eye Care Awareness Day', '2026-12-20', 'Community Centre', 'Upcoming'), "
    			+ "('Free Vision Screening', '2026-11-01', 'Tampines Hub', 'Cancelled'),"
				+ "('Children Vision Screening', '2026-11-01', 'Tampines Hub', 'Cancelled'),"
				+ "('Senior Vision Check', '2026-12-12', 'Toah Payoh Community Centre', 'Upcoming'),"
				+ "('Diabetic Eye Screening', '2026-12-19', 'Jurong West Community Club', 'Ongoing'),"
				+ "('Weekend Vision Screening', '2026-12-08', 'Bedok Community Centre', 'Ongoing'),"
				+ "('Student Eye Health Day', '2026-11-10', 'Singapore Polytechnic', 'Upcoming')";

			stmt.executeUpdate(insertEvents);

			//inserting registration
			
			String insertRegistrations =
		    "INSERT INTO registrations "
			    + "(participant_id, event_id, status) "
			    + "VALUES "
			    + "(1, 1, 'Registered'), "
			    + "(1, 2, 'Registered'), "
			    + "(2, 1, 'Attended'), "
			    + "(2, 3, 'Attended'), "
			    + "(3, 2, 'Withdrawn'), "
			    + "(4, 4, 'Registered')";

			stmt.executeUpdate(insertRegistrations);

			
		
    	stmt.close();
		conn.close();
		
		 response.sendRedirect(returnUrl +"?msg=success");
		
    } catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        out.println("Unable to connect to the database.");
    }
%>
</body>
</html>