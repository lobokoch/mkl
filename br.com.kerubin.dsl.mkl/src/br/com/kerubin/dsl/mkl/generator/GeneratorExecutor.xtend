package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Service
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

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
	
	def String getBasePackage() {
		service.configuration.groupId
	}
	
	def String getServicePackage(Service service) {
		basePackage + '.' + service.domain + '.' + service.name
	}
	
	def String getPackagePageResult(Service service) {
		basePackage + '.' + service.domain + '.' + service.name + ".common"
	}
	
	def String getImportPageResult(Service service) {
		'import ' + service.packagePageResult + ".PageResult;"
	}
	
	def String getServicePackagePath(Service service) {
		val path = getServicePackage(service).replace('.', '/')
		path
	}
	
	def String getPackage(Entity entity) {
		getServicePackage(entity.service) + '.entity.' + entity.name
	}
	
	def String getPackagePath(Entity entity) {
		val path = entity.package.replace('.', '/')
		path
	}
	
	def String getEntityImport(Entity entity) {
		'import ' + entity.package + '.' + entity.toEntityName + ';'
	}
	
	def String getEntityDTOImport(Entity entity) {
		'import ' + entity.package + '.' + entity.toEntityDTOName + ';'
	}
	
	def String getEntityDTOConverterImport(Entity entity) {
		'import ' + entity.package + '.' + entity.toDTOConverterName + ';'
	}
	
}