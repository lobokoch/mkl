package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaServiceConstantsGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = clientGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + service.toServiceConstantsName + '.java'
		generateFile(fileName, generatePageResult)
	}
	
	def CharSequence generatePageResult() {
		'''
		package «service.getServicePackage»;
		
		public interface «service.toServiceConstantsName» {
			
			String DOMAIN = "«service.domain.toLowerCase»";
			String SERVICE = "«service.name.toLowerCase»";
			
			interface Events {
				
			}
		
		}
		'''
	}
	
}