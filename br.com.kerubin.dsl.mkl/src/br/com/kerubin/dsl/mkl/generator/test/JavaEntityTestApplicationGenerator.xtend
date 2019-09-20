package br.com.kerubin.dsl.mkl.generator.test

import br.com.kerubin.dsl.mkl.generator.BaseGenerator
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaEntityTestApplicationGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateTestApplication
	}
	
	def generateTestApplication() {
		val basePakage = getServerTestGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + service.toMainTestApplicationClassName + '.java'
		generateFile(fileName, doGenerateTestApplication)
	}
	
	def CharSequence doGenerateTestApplication() {
		'''
		package «service.servicePackage»;
		
		import org.springframework.boot.autoconfigure.SpringBootApplication;
		import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
		
		@SpringBootApplication
		@EnableJpaRepositories("br.com.kerubin.api")
		public class «service.toMainTestApplicationClassName» {
		
			// This source is for test purpose only.
		}
		
		'''
	}
	
	def CharSequence generateDefaultTestProperties() {
		
		'''
		# spring.flyway.enabled=false
		spring.flyway.locations=classpath:/db/migration/test/
		
		'''
		
	}
			
}