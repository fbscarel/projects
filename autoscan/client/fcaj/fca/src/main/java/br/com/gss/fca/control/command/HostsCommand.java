package br.com.gss.fca.control.command;

import br.com.gss.fca.Messages;
import br.com.gss.fca.exception.FCAException;
import br.com.gss.fca.gui.FeedbackDelegate;
import br.com.gss.fca.model.Configuration;
import br.com.gss.fca.util.FileUtil;
import br.com.gss.fca.util.WindowsUtil;

public class HostsCommand extends AbstractCommand {

	public HostsCommand(FeedbackDelegate feebackWindow) {
		super(feebackWindow);
	}

	@Override
	protected void executeCommand() throws FCAException {
		String hosts = WindowsUtil.getHostsPath();
		FileUtil.copyFile(hosts, Configuration.getInstance().getHostsOutputPath());
	}

	@Override
	public String getCommandName() {
		return Messages.getString("command.hosts");
	}

}
