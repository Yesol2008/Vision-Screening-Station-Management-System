<%--
	Yesol's part (placeholder to test the redirect from register.jsp)
	TODO (Yesol): print the registration success message on the login page
--%>

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<% if ("registered".equals(request.getParameter("msg"))) { %>
	<p>Account registered successfully. You can now sign in to your account.</p>
<% } %>