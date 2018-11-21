package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Service
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import org.eclipse.xtext.generator.IFileSystemAccess2
import br.com.kerubin.dsl.mkl.model.Enumeration

class GeneratorExecutor {
	
	protected BaseGenerator baseGenerator
	
	new (BaseGenerator baseGenerator) {
		this.baseGenerator = baseGenerator
	}
	
	def IFileSystemAccess2 getFsa() {
		baseGenerator.fsa
	}
	
	def generateFile(String fileName, CharSequence contents) {
		baseGenerator.generateFile(fileName, contents)
	}
	
	def generateFile(String fileName, CharSequence contents, String outputConfigurationName) {
		baseGenerator.generateFile(fileName, contents, outputConfigurationName)
	}
	
	def generateFileForApp(String fileName, CharSequence contents) {
		baseGenerator.generateFile(fileName, contents, MklOutputConfigurationProvider.OUTPUT_KEEPED)
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
	
	def String textUnderToTextCamel(String text) {
		val names = text.split("_")
		val result = names.map[toFirstUpper].join
		result		
	}
	
	def String getServicePath(Entity entity) {
		entity.service.servicePath
	}
	
	def String getServicePath(Service service) {
		val path = service.domain.removeUnderline + '/' + service.name.removeUnderline + '/'
		path
	}
	
	
	def String getServicePackage(Service service) {
		basePackage + '.' + service.domain.removeUnderline + '.' + service.name.removeUnderline
	}
	
	def String getPackagePageResult(Service service) {
		basePackage + '.' + service.domain.removeUnderline + '.' + service.name.removeUnderline + ".common"
	}
	
	def String getImportPageResult(Service service) {
		'import ' + service.packagePageResult + ".PageResult;"
	}
	
	def String getServicePackagePath(Service service) {
		val path = getServicePackage(service).replace('.', '/')
		path
	}
	
	def String getPackage(Entity entity) {
		getServicePackage(entity.service) + '.entity.' + entity.name.toLowerCase
	}
	
	def String getEnumPackage(Enumeration enumeration) {
		getServicePackage(enumeration.service) + '.' + enumeration.name.toFirstUpper
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