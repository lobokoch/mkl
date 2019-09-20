package br.com.kerubin.dsl.mkl.generator.test

import br.com.kerubin.dsl.mkl.generator.BaseGenerator
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.JavaPostgreSQLGenerator

class JavaEntityTestResourcesGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateTestResourcesProperties
		generateTestResourcesSQL
	}
	
	def generateTestResourcesSQL() {
		val javaPostgreSQLGenerator = new JavaPostgreSQLGenerator(baseGenerator)
		val basePakage = getServerTestResourceGenSourceFolder
		val fileName = basePakage + 'db/migration/test/V1__Creation_Tables_' + javaPostgreSQLGenerator.databaseName + '.sql'
		val sql = javaPostgreSQLGenerator.generateSQL
		generateFile(fileName, sql)
	}
	
	def generateTestResourcesProperties() {
		val basePakage = getServerTestResourceGenSourceFolder
		val fileName = basePakage + 'default-test.properties'
		generateFile(fileName, generateDefaultTestProperties)
	}
	
	def CharSequence generateDefaultTestProperties() {
		
		'''
		# spring.flyway.enabled=false
		spring.flyway.locations=classpath:/db/migration/test/
		
		'''
		
	}
			
}