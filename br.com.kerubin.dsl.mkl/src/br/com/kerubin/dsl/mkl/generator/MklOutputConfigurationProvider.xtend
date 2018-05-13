package br.com.kerubin.dsl.mkl.generator

import org.eclipse.xtext.generator.OutputConfigurationProvider

class MklOutputConfigurationProvider extends OutputConfigurationProvider {
	
	public static val OUTPUT_DIRECTORY = "."
	
	
	//Changes the default output to root with "."
	override getOutputConfigurations() {
		super.outputConfigurations => [
			head.outputDirectory = OUTPUT_DIRECTORY
		]
	}
	
}