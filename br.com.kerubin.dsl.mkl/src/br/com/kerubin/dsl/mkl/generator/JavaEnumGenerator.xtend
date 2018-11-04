package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.EnumItem
import br.com.kerubin.dsl.mkl.model.Enumeration

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaEnumGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val enums = service.elements.filter(Enumeration) 
		enums.forEach[generateEnumeration]
	}
	
	def generateEnumeration(Enumeration enumeration) {
		val basePakage = clientGenSourceFolder
		val packagePath = service.servicePackagePath
		val fileName = basePakage + '/' + packagePath + '/' + enumeration.name.toFirstUpper + '.java'
		generateFile(fileName, enumeration.generateFile)
	}
	
	def CharSequence generateFile(Enumeration enumeration) {
		enumeration.items
		
		'''
		package «service.servicePackage»;
		
		public enum «enumeration.name.toFirstUpper» {
			«enumeration.items.map[it.buildEnumItem].join(',\r\n')»
		}
		
		'''
	}
	
	def String buildEnumItem(EnumItem item) {
		item.name
	}
	
}