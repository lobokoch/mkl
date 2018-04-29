package br.com.kerubin.dsl.mkl.generator

class GeneratorExecutor {
	
	protected BaseGenerator baseGenerator
	
	new (BaseGenerator baseGenerator) {
		this.baseGenerator = baseGenerator
	}
	
	def generateFile(String fileName, CharSequence contents) {
		baseGenerator.generateFile(fileName, contents)
	}
	
	def getService() {
		baseGenerator.service
	}
	
	def getConfiguration() {
		baseGenerator.configuration
	}
	
	def getEntities() {
		baseGenerator.entities
	}
}