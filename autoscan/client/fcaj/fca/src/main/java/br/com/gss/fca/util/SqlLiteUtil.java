package br.com.gss.fca.util;

import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import br.com.gss.fca.Messages;
import br.com.gss.fca.exception.FCAException;

public class SqlLiteUtil {
	
	public static interface ResultSetMapper<T> {
		public T map(ResultSet rs) throws SQLException;
	}
	
	private static void loadDriver() {
		try {
			Class.forName("org.sqlite.JDBC");
		} catch (ClassNotFoundException e) {
			throw new FCAException(Messages.getString("error.driver.not.found"),e);
		}
	}
	
	public static Connection getConnection(File dbFile) {
		try {
			loadDriver();
			return DriverManager.getConnection("jdbc:sqlite:"+dbFile.getCanonicalPath());
		} catch (SQLException e) {
			throw new FCAException(Messages.getString("error.connection"),e);
		} catch (IOException e) {
			throw new FCAException(Messages.getString("error.file.path"),e);
		}
	}
	
	public static <T> List<T> query(Connection conn, String sql, Object[] params, ResultSetMapper<T> mapper){
		PreparedStatement stmt = null;
		ResultSet rs = null;
		try {
			stmt = conn.prepareStatement(sql);
			setParameters(stmt, params);
			rs = stmt.executeQuery();
			
			List<T> result = new ArrayList<T>();
			while(rs.next())
				result.add(mapper.map(rs));
			
			return result;
		} catch (SQLException e) {
			throw new FCAException(Messages.getString("error.sql"), e);
		} finally {
			silentClose(null, stmt, rs);
		}
	}
	
	private static void setParameters(PreparedStatement stmt, Object[] params) throws SQLException {
		if(params == null)
			return;
		
		for(int i = 0; i < params.length; i++) {
			Object param = params[i];
			int pindex = i + 1;
			if(param instanceof Date)
				stmt.setDate(pindex, new java.sql.Date(((Date)param).getTime()));
			else if(param instanceof Byte)
				stmt.setLong(pindex, ((Byte)param).byteValue());
			else if(param instanceof Short)
				stmt.setLong(pindex, ((Short)param).shortValue());
			else if(param instanceof Integer)
				stmt.setInt(pindex, ((Integer)param).intValue());
			else if(param instanceof Long)
				stmt.setLong(pindex, ((Long)param).longValue());
			else if(param instanceof String)
				stmt.setString(pindex, (String)param);
			else
				stmt.setObject(pindex, param);
		}
	}
	
	public static void silentClose(Connection conn, PreparedStatement stmt, ResultSet rs) {
		try {
			if(rs != null)
				rs.close();
			if(stmt != null)
				stmt.close();
			if(conn != null)
				conn.close();
		} catch (SQLException e) {
			
		}
	}
}
