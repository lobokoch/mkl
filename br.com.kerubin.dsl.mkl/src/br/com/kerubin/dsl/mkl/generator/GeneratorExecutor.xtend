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
	
	def String getWebServicePath(Service service) {
		val path = service.servicePath
		val fullPath = path.webDir
		fullPath
	}
	
	def String getWebServiceI18nPath(Service service) {
		val path = service.servicePath + 'i18n/'
		val fullPath = path.webDir
		fullPath
	}
	
	def String getWebEntityPath(Entity entity) {
		val path = entity.service.servicePath + entity.name.toLowerCase.removeUnderline + '/'
		val fullPath = path.webDir
		fullPath
	}
	
	def String getWebEntityPathShort(Entity entity) {
		val path = entity.service.servicePath + entity.name.toLowerCase.removeUnderline + '/'
		path
	}
	
	/*def String getWebServicePath(Entity entity) {
		entity.service.servicePath + '/service/'
	}*/
	
	def String getServicePath(Entity entity) {
		entity.service.servicePath
	}
	
	def String getServicePath(Service service) {
		val path = service.domain.removeUnderline + '/' + service.name.removeUnderline + '/'
		path
	}
	
	def String getServiceWebTranslationPath(Service service) {
		val path = './' + service.domain.webName + '/' + service.name.webName + '/' + I18N_PATH_NAME + '/'
		path
	}
	
	def String getServiceWebTranslationPathName(Service service) {
		val path = service.serviceWebTranslationPath + service.toTranslationServiceName
		path
	}
	
	def String getServiceWebTranslationComponentPath() {
		val path = './../' + I18N_PATH_NAME + '/'
		path
	}
	
	def String getServiceWebTranslationComponentPathName(Service service) {
		val path = serviceWebTranslationComponentPath + service.toTranslationServiceName
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