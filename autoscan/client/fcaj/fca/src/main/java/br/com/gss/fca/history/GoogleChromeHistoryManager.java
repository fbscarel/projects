package br.com.gss.fca.history;

import java.io.File;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.apache.commons.lang3.Validate;

import br.com.gss.fca.Messages;
import br.com.gss.fca.history.HistoryItem.Browser;
import br.com.gss.fca.util.BrowserUtil;
import br.com.gss.fca.util.SqlLiteUtil;
import br.com.gss.fca.util.SqlLiteUtil.ResultSetMapper;

public class GoogleChromeHistoryManager implements HistoryManager {
	private List<HistoryItem> historyList;
	
	public List<HistoryItem> getHistory(Date startDate, Date endDate) {
		Validate.notNull(startDate, Messages.getString("error.not.null", new String[]{"startDate"}));
		Validate.notNull(endDate, Messages.getString("error.not.null", new String[]{"endDate"}));
		
		if(historyList == null) {
			historyList = new ArrayList<HistoryItem>();
			File dataFile = BrowserUtil.getGoogleChromeDataFile();
			if(dataFile != null && dataFile.exists()){
				Connection conn = SqlLiteUtil.getConnection(dataFile);
				
				// Visit time in Google Chrome (windows) is FILETIME representation, whose
				// epoch is  1601-01-01 00:00:00 UTC and is measured in microseconds.
				// Java Date epoch is 1970-01-01 and is measured in milliseconds.
				// To convert to Java Date, subtract 11644473600000000 and divide by 1000.
				String sql = "SELECT                                                 "+
							 " u.url,                                                "+
							 " (v.visit_time - 11644473600000000)/1000 AS visit_time "+
							 "FROM                                                   "+
							 " urls AS u, visits AS v                                "+
							 "WHERE                                                  "+
							 " u.id = v.url                                          "+
							 "AND ((v.visit_time - 11644473600000000)/1000) >= ?     "+
							 "AND ((v.visit_time - 11644473600000000)/1000) <= ?     ";
				
				Object[] params = new Object[]{startDate.getTime(), endDate.getTime()};
				
				try {
					historyList = SqlLiteUtil.query(conn, sql, params, new ResultSetMapper<HistoryItem>() {
						public HistoryItem map(ResultSet rs) throws SQLException {
							HistoryItem item = new HistoryItem();
							item.setBrowser(Browser.GOOGLE_CHROME);
							item.setUrl(rs.getString("url"));
							item.setVisitTime(new Date(rs.getLong("visit_time")));
							return item;
						}
					});
				} finally {
					SqlLiteUtil.silentClose(conn, null, null);
				}
			}
		}
		
		return historyList;
	}
	
}
