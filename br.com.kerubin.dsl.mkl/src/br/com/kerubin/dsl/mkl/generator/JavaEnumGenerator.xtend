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
		val enumName = enumeration.name.toFirstUpper
		
		'''
		package «service.servicePackage»;
		
		public enum «enumName» {
			«enumeration.items.map[it.buildEnumItem].join(',\r\n')»;
			«IF enumeration.hasSomeValueStr»
			
			private String value;
			
			private «enumName»(String value) {
				this.value = value;
			}
			
			public String getValue() {
				return value;
			}
			«ENDIF»
		}
		
		'''
	}
	
	def CharSequence buildEnumItem(EnumItem item) {
		'''«item.name»«IF item.hasValueStr»("«item.valueStr»")«ENDIF»'''
	}
	
}