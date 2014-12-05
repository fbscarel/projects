package br.com.gss.fca;

import java.util.Calendar;
import java.util.Date;

import br.com.gss.fca.history.GoogleChromeHistoryManager;
import br.com.gss.fca.history.HistoryItem;
import br.com.gss.fca.history.HistoryManager;
import br.com.gss.fca.history.InternetExplorerHistoryManager;
import br.com.gss.fca.history.MozillaFirefoxHistoryManager;

public class BrowserHistoryTest {
	public static void main(String... args){
		Calendar startCal = Calendar.getInstance();
		startCal.set(Calendar.YEAR, 2014);
		startCal.set(Calendar.MONTH, Calendar.SEPTEMBER);
		startCal.set(Calendar.DAY_OF_MONTH, 1);
		
		Calendar endCal = Calendar.getInstance();
		endCal.set(Calendar.YEAR, 2014);
		endCal.set(Calendar.MONTH, Calendar.NOVEMBER);
		endCal.set(Calendar.DAY_OF_MONTH, 1);

		testInternetExplorerHistory(startCal.getTime(), endCal.getTime());
		testGoogleChromeHistory(startCal.getTime(), endCal.getTime());
		testMozillaFirefoxHistory(startCal.getTime(), endCal.getTime());
	}
	
	private static void testInternetExplorerHistory(Date startDate, Date endDate) {
		HistoryManager manager = new InternetExplorerHistoryManager();
		System.out.println("###### IE #####");
		for(HistoryItem item:manager.getHistory(startDate, endDate))
			System.out.println(item.toString());
	}
	
	private static void testGoogleChromeHistory(Date startDate, Date endDate) {
		HistoryManager manager = new GoogleChromeHistoryManager();
		System.out.println("###### CHROME #####");
		for(HistoryItem item:manager.getHistory(startDate, endDate))
			System.out.println(item.toString());	
	}
	
	private static void testMozillaFirefoxHistory(Date startDate, Date endDate) {
		HistoryManager manager = new MozillaFirefoxHistoryManager();
		System.out.println("###### FIREFOX #####");
		for(HistoryItem item:manager.getHistory(startDate, endDate))
			System.out.println(item.toString());
	}
}
