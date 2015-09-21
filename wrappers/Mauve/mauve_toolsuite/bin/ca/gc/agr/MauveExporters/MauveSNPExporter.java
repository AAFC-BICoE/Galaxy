package ca.gc.agr.MauveExporters;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import org.gel.mauve.BaseViewerModel;
import org.gel.mauve.MauveFormatException;
import org.gel.mauve.ModelBuilder;
import org.gel.mauve.ModelProgressListener;
import org.gel.mauve.XmfaViewerModel;
import org.gel.mauve.analysis.SnpExporter;

public class MauveSNPExporter implements ModelProgressListener {	

	public static void main(String [] args) throws IOException, MauveFormatException {
		BaseViewerModel model;
		XmfaViewerModel xvm;
		
		if ( args.length < 2 ){
			printOut("Usage: java MauveSNPExporter.class <XMFA Alignment File> <Output SNP File>");
			System.exit(1);
		}
		
		MauveSNPExporter parser = new MauveSNPExporter();
		
		String inputFile = args[0];
		String outFile = args[1];
		
		printOut("Loading XMFA alignment file ".concat( inputFile ));
		File alignmentFile = new File( inputFile );
		
		model =  ModelBuilder.buildModel(alignmentFile, parser);
		
		printOut("Parsing XMFA alignment file completed.");
		
		if ( model instanceof XmfaViewerModel ){
			xvm = (XmfaViewerModel) model;
		} else {
			printErr("Only mauve's XMFA alignments are supported for exporting SNPs");
			System.exit(1);
			return;
		}
		
		if ( xvm.getBackboneList() == null ){
			printErr("Can't export SNPs because the backbone is missing.  Did you run Mauve with the skip backbone optione?");
		}
		
		BufferedWriter writer = new BufferedWriter( new FileWriter( outFile ) );
		
		printOut("Trying to export SNPs to file ".concat(outFile));
		SnpExporter.export(xvm, xvm.getXmfa(), writer );
		printOut("Creating SNPs file completed.");
		
		System.exit(0);
	}
	

	public static void printErr (String err){
		System.err.println(err);
	}
	
	public static void printOut (String out){
		System.out.println(out);
	}
	
	@Override
	public void alignmentEnd(int arg0) {}

	@Override
	public void alignmentStart() {	}

	@Override
	public void buildStart() {	}

	@Override
	public void done() { }

	@Override
	public void downloadStart() {	}

	@Override
	public void featureStart(int arg0) {	}

}
