package br.com.kerubin.dsl.mkl.generator.test

import br.com.kerubin.dsl.mkl.generator.BaseGenerator
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import static extension br.com.kerubin.dsl.mkl.generator.test.TestUtils.*

class JavaEntityTestVisitorGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	// var Set<String> imports = newLinkedHashSet
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		if (service.isEnableCustomTestConfig) {
			generateFiles
		}
	}
	
	def generateFiles() {
		generateTestVisitorInterface
		generateTestVisitorOperationEnum
		generateTestVisitorInterfaceDefaultImpl
	}
	
	def generateTestVisitorInterface() {
		val basePakage = getServerTestGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + service.toServiceTestVisitorInterfaceClassName + '.java'
		generateFile(fileName, doGenerateTestVisitorInterface)
	}
	
	def generateTestVisitorOperationEnum() {
		val basePakage = getServerTestGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + service.toServiceTestVisitorOperationEnumName + '.java'
		generateFile(fileName, doGenerateTestVisitorOperationEnum)
	}
	
	def generateTestVisitorInterfaceDefaultImpl() {
		val basePakage = getServerTestGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + service.toServiceTestVisitorInterfaceDafaultImplClassName + '.java'
		generateFile(fileName, doGenerateTestVisitorInterfaceDefaultImpl)
	}
	
	def CharSequence doGenerateTestVisitorInterface() {
		
		val package = '''
		package «service.servicePackage»;
		
		'''
		
		val body = '''
		
		public interface «service.toServiceTestVisitorInterfaceClassName» {
			
			void visit(«service.toServiceEntityBaseTestClassName» testInstance, String testMethodName, Object testSubject, «service.toServiceTestVisitorOperationEnumName» testOperation);
		
		}
		'''
		
		package + body
		
	}
	
	def CharSequence doGenerateTestVisitorInterfaceDefaultImpl() {
		
		val package = '''
		package «service.servicePackage»;
		
		'''
		
		val body = '''
		import org.springframework.stereotype.Component;
		
		@Component
		public class «service.toServiceTestVisitorInterfaceDafaultImplClassName» implements «service.toServiceTestVisitorInterfaceClassName» {
			
			@Override
			public void visit(«service.toServiceEntityBaseTestClassName» testInstance, String testMethodName, Object testSubject, «service.toServiceTestVisitorOperationEnumName» testOperation) {
				
				// Do nothing for default, can be specialized by sub classes.
				
			}
		
		}
		'''
		
		package + body
		
	}
	
	def CharSequence doGenerateTestVisitorOperationEnum() {
		
		val package = '''
		package «service.servicePackage»;
		
		'''
		
		val body = '''
		
		public enum «service.toServiceTestVisitorOperationEnumName» {
			
			BEFORE, AFTER;
			
		}
		'''
		
		package + body
		
	}
	
	
	
			
}