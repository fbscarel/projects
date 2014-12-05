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

public class MozillaFirefoxHistoryManager implements HistoryManager {
	private List<HistoryItem> historyList;
	
	public List<HistoryItem> getHistory(Date startDate, Date endDate) {
		Validate.notNull(startDate, Messages.getString("error.not.null", new String[]{"startDate"}));
		Validate.notNull(endDate, Messages.getString("error.not.null", new String[]{"endDate"}));
		
		if(historyList == null) {
			historyList = new ArrayList<HistoryItem>();
			File dataFile = BrowserUtil.getMozillaFirefoxDataFile();
			if(dataFile != null && dataFile.exists()){
				Connection conn = SqlLiteUtil.getConnection(dataFile);
				// Visit time in Mozilla Firefox is measured in microseconds.
				// Java Date  is measured in milliseconds. To convert to Java Date,
				// visit time by 1000.
				String sql = "SELECT                                   "+
							 " p.url,                                  "+
							 " v.visit_date/1000 AS visit_time         "+
							 "FROM                                     "+
							 " moz_places AS p, moz_historyvisits AS v "+
							 "WHERE                                    "+
							 " p.id = v.id                             "+
							 " AND (v.visit_date/1000) >= ?            "+
							 " AND (v.visit_date/1000) <= ?            ";
				Object[] params = new Object[]{startDate.getTime(), endDate.getTime()};
				
				try {
					historyList = SqlLiteUtil.query(conn, sql, params, new ResultSetMapper<HistoryItem>() {
						public HistoryItem map(ResultSet rs) throws SQLException {
							HistoryItem item = new HistoryItem();
							item.setBrowser(Browser.MOZILLA_FIREFOX);
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
