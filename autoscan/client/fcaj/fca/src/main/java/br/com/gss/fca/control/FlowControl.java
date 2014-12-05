package br.com.gss.fca.control;

import java.util.ArrayList;
import java.util.List;

import br.com.gss.fca.control.command.AbstractCommand;
import br.com.gss.fca.control.command.HijackthisCommand;
import br.com.gss.fca.control.command.HostsCommand;
import br.com.gss.fca.control.command.OpenExplorer;
import br.com.gss.fca.control.command.PackCommand;
import br.com.gss.fca.control.command.browsers.ChromeAnalysisCommand;
import br.com.gss.fca.control.command.browsers.FirefoxAnalysisCommand;
import br.com.gss.fca.control.command.browsers.IeAnalysisCommand;
import br.com.gss.fca.gui.FeedbackDelegate;

/**
 * Controls the analysis.
 * @author Paula.Fernandes
 */
public class FlowControl {

	private static FlowControl instance;
	private int commandIndex = 0;
	private List<AbstractCommand> commands = null;
	private FeedbackDelegate feedbackDelegate = null;
	
	private FlowControl(){
		commands = new ArrayList<AbstractCommand>();
	}
	
	public static FlowControl getInstance() {
		if(instance==null){
			instance = new FlowControl();
			instance.restart();
		}
		return instance;
	}

	public void registerDelegate(FeedbackDelegate feedbackDelegate) {
		this.feedbackDelegate = feedbackDelegate;
	}
	 
	private void createCommands() {
		this.commands.add(new HijackthisCommand(feedbackDelegate));
		this.commands.add(new HostsCommand(feedbackDelegate));
		this.commands.add(new ChromeAnalysisCommand(feedbackDelegate));
		this.commands.add(new FirefoxAnalysisCommand(feedbackDelegate));
		this.commands.add(new IeAnalysisCommand(feedbackDelegate));
		this.commands.add(new PackCommand(feedbackDelegate));
		this.commands.add(new OpenExplorer(feedbackDelegate));
//		this.commands.add(new SendToAnalysisCommand(feedbackDelegate));
	}
	
	public int commandsCount(){
		if(this.commands==null){
			return 0;
		}
		return this.commands.size();
	}
//	
	public AbstractCommand getNextCommand() {
         if (commands == null) {
             return null;
         }
         if (this.commandIndex >= this.commands.size()) {
             return null;
         }
         return commands.get(this.commandIndex++);
     }

	public void executeNextCommand() {
		AbstractCommand c = getNextCommand();
		c.execute();
	}

	public boolean hasNextCommand() {
		if (this.commandIndex >= this.commands.size()) {
            return false;
        }
		return true;
	}
	
	public void restart() {
		this.commandIndex = 0;
		this.commands.clear();
		this.createCommands();
	}
	
}
