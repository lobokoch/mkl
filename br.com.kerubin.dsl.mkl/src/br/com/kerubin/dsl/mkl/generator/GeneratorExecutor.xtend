package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Enumeration
import br.com.kerubin.dsl.mkl.model.Service
import org.eclipse.xtext.generator.IFileSystemAccess2

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

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
	
	def canGenerateEntity(Entity entity) {
		var can = !entity.isGenerationDisabled
		can
	}
	
	def canGenerateController(Entity entity) {
		val not = entity.isGenerationDisabled() || (entity.hasDisableGeneration && entity.disableGeneration.controller)
		!not
	}
	
	def canGenerateEntityJPA(Entity entity) {
		val not = entity.isGenerationDisabled() || (entity.hasDisableGeneration && entity.disableGeneration.entityJPA)
		!not
	}
	
	def canGenerateRepository(Entity entity) {
		val not = entity.isGenerationDisabled() || (entity.hasDisableGeneration && entity.disableGeneration.repository)
		!not
	}
	
	def canGenerateServiceImpl(Entity entity) {
		val not = entity.isGenerationDisabled() || (entity.hasDisableGeneration && entity.disableGeneration.serviceImpl)
		!not
	}
	
	def canGenerateServiceInterface(Entity entity) {
		val not = entity.isGenerationDisabled() || (entity.hasDisableGeneration && entity.disableGeneration.serviceInterface)
		!not
	}
	
	def canGenerateEntityDTO(Entity entity) {
		val not = entity.isGenerationDisabled() || (entity.hasDisableGeneration && entity.disableGeneration.entityDTO)
		!not
	}
	
	
	def getEntities() {
		baseGenerator.entities.filter[canGenerateEntity]
	}
	
	def getEnums() {
		baseGenerator.enums
	}
	
	def String getBasePackage() {
		service.configuration.groupId
	}
	
	def String textUnderToTextCamel(String text) {
		text.toCamelCase
	}
	
	def String getServiceNameCamelCase(Service service) {
		val result = service.domain.toCamelCase + service.name.toCamelCase
		result
	}
	
	def String getWebServicePath(Service service) {
		val path = service.servicePath
		val fullPath = path.webDir
		fullPath
	}
	
	def String getWebServiceI18nPath(Service service) {
		val path = service.servicePath + 'i18n/'
		val fullPath = path./*webDir*/webModulesDir
		fullPath
	}
	
	def String getWebServiceEnumPath(Service service) {
		val path = service.servicePath + ENUMS_PATH_NAME + '/'
		val fullPath = path./*webDir*/webModulesDir
		fullPath
	}
	
	def String getWebServiceNavbarPath(Service service) {
		val path = service.servicePath + NAVBAR + '/'
		val fullPath = path./*webDir*/webModulesDir
		fullPath
	}

	
	def String getWebEntityPath(Entity entity) {
		val path = entity.service.servicePath + entity.name.toLowerCase.removeUnderline + '/'
		val fullPath = path.webModulesDir
		fullPath
	}
	
	/*def String getWebEntityModulesPath(Entity entity) {
		val path = entity.service.servicePath + entity.name.toLowerCase.removeUnderline + '/'
		// web/src-gen/app/
		val fullPath = path.webModulesDir
		fullPath
	}*/
	
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
	
	def String getServiceWebEnumsPath() {
		val path = './../' + ENUMS_PATH_NAME + '/'
		path
	}
	
	def String getServiceWebEnumsPathName(Service service) {
		val path = serviceWebEnumsPath + service.toEnumModelName
		path
	}
	
	def String getExternalServicePackage(Entity entity) {
		val domainName = entity?.subscribeEntityEvents?.externalDomain
		val serviceName = entity?.subscribeEntityEvents?.externalService
		
		basePackage + '.' + domainName?.removeUnderline + '.' + serviceName?.removeUnderline
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
	
	def String getServiceName(Service service) {
		service.name.getNameExt
	}
	
	def String getDomainName(Service service) {
		service.domain.getNameExt
	}
	
	def String getNameExt(String name) {
		//name.removeUnderline.toFirstUpper
		name.toCamelCase
	}
	
	def String toExternalServiceConstantsName(Entity entity) {
		val domainName = entity?.subscribeEntityEvents?.externalDomain
		val serviceName = entity?.subscribeEntityEvents?.externalService
		domainName?.toCamelCase + serviceName?.toCamelCase + "Constants"
	}
	
	def String getImportExternalServiceConstants(Entity entity) {
		'import ' + entity.getExternalServicePackage + '.' + entity.toExternalServiceConstantsName + ';'
	}
	
	def String getImportExternalEntityEvent(Entity entity) {
		'import ' + entity.getExternalEntityPakage + '.' + entity.toEntityEventName + ';'
	}
	
	def String getImportExternalEnumeration(Entity entity, Enumeration enumeration) {
		'import ' + entity.getExternalEntityPakage + '.' + enumeration.name + ';'
	}
	
	/*def String getImportExternalEntityEvent(Entity entity) {
		'import ' + entity.getExternalEntityPakage + '.' + entity.toEntityEventName + ';'
	}*/
	
	def String getExternalEntityPakage(Entity entity) {
		entity.getExternalServicePackage + '.entity.' + entity.name.toLowerCase
	}
	
	def String toServiceConstantsName(Service service) {
		service.domain.toCamelCase + service.name.toCamelCase + "Constants"
	}
	
	def String getImportServiceConstants(Service service) {
		'import ' + service.servicePackage + '.' + service.toServiceConstantsName + ';'
	}
	
	def String getImportServiceConstants(Entity entity) {
		val service = entity.service
		'import ' + service.servicePackage + '.' + service.toServiceConstantsName + ';'
	}
	
	def String toServiceContextName(Service service) {
		//service.domainName + service.serviceName + "Constants"
		'ServiceContext'
	}
	
	def String toServiceHandlerInterceptorAdapterName(Service service) {
		//service.domainName + service.serviceName + "Constants"
		'ServiceHandlerInterceptorAdapter'
	}
	
	def String toMessageAfterReceivePostProcessorsName(Service service) {
		'MessageAfterReceivePostProcessors'
	}
	
	def String toServiceWebMvcConfigurerAdapterName(Service service) {
		//service.domainName + service.serviceName + "Constants"
		'ServiceWebMvcConfigurerAdapter'
	}
	
	def String getImportServiceContext(Service service) {
		'import ' + service.servicePackage + '.' + service.toServiceConstantsName + ';'
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