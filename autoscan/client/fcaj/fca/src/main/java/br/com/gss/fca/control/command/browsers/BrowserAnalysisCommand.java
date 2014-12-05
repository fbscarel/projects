package br.com.gss.fca.control.command.browsers;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.util.Date;
import java.util.List;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.lang3.time.DateUtils;

import br.com.gss.fca.Messages;
import br.com.gss.fca.control.command.AbstractCommand;
import br.com.gss.fca.exception.FCAException;
import br.com.gss.fca.gui.FeedbackDelegate;
import br.com.gss.fca.history.HistoryItem;
import br.com.gss.fca.model.Configuration;
import br.com.gss.fca.util.FileUtil;

public abstract class BrowserAnalysisCommand extends AbstractCommand{
	
	public BrowserAnalysisCommand(FeedbackDelegate feebackWindow) {
		super(feebackWindow);
	}

	protected File getBrowserPath() {
		String browserPath = Configuration.getInstance().getBrowserPath();
		FileUtil.createDirectory(browserPath);
		return new File(browserPath);
	}
	
	protected void writeToCSV(String fileName, List<HistoryItem> history){
		Writer csvFile = null;
		CSVPrinter printer = null;
		try {
			csvFile = new FileWriter( new File(getBrowserPath(), fileName));
			printer = new CSVPrinter(csvFile, CSVFormat.EXCEL.withDelimiter(';'));
			if(history != null) {
				for(HistoryItem item: history) 
					printer.printRecord(item.getVisitTimeFmt(), item.getUrl());
			}
		} catch (IOException e) {
			throw new FCAException(Messages.getString("error.write.csv"), e);
		} finally {
			try {
				if(printer != null)
					printer.close();
				if(csvFile != null)
					csvFile.close();
			} catch (IOException e) {
				// Close quietly
			}
		}
	}
	
	protected Date getStartDate(){
		return DateUtils.addMonths(Configuration.getInstance().getIncidentDate(), -2);
	}
	
	protected Date getEndDate(){
		return DateUtils.addWeeks(Configuration.getInstance().getIncidentDate(), 1);
	}
}
