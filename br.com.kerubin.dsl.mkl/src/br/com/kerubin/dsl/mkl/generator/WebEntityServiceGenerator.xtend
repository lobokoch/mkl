package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.FilterOperatorEnum
import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import br.com.kerubin.dsl.mkl.generator.web.analitycs.WebAnalitycsGenerator

class WebEntityServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	StringConcatenationExt imports
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateService]
	}
	
	def generateService(Entity entity) {
		val path = entity.webEntityPath
		val entityFile = path + entity.toEntityWebServiceName + '.ts'
		generateFile(entityFile, entity.doGenerateEntityWebService)
	}
	
	def CharSequence normalizeTimeFields(Entity entity) {
		
		val name = entity.fieldName
		val timeSlots = entity.slots.filter[isTime]
		
		'''
		
		�name� = {... �name�}; // Make a clone.
		�timeSlots.map['''�name�.�it.fieldName� = this.�getTimeAsStringMethodName�(�name�.�it.fieldName�);'''].join('\r\n')�
		
		'''
	}
	
	def CharSequence doGenerateEntityWebService(Entity entity) {
		imports = new StringConcatenationExt()
		entity.initializeImports()
		
		// val webName = entity.toWebName
		val dtoName = entity.toDtoName
		val varName = dtoName.toFirstLower
		val serviceName = entity.toEntityWebServiceClassName
		val entitySumFieldsClassName = entity.toEntitySumFieldsName
		
		val slots = entity.slots
		val slotsListFilter = slots.filter[hasListFilter]
		
		val ruleActions = entity.ruleActions
		
		val fkSlots = entity.getEntitySlots
		
		imports.add('''import { �dtoName� } from './�entity.toEntityWebModelName�';''')
		imports.add('''import { �entity.toAutoCompleteName� } from './�entity.toEntityWebModelName�';''')
		slots.filter[it.isEntity && it.asEntity.isNotSameName(entity)].forEach[
			imports.add('''import { �it.asEntity.toDtoName� } from './�entity.toEntityWebModelNameWithPah(it)�';''')
		]
		
		imports.add('''import { �entity.toEntityListFilterClassName� } from './�entity.toEntityWebModelName�';''')
		
		slotsListFilter.filter[isListFilterMany].forEach[
			imports.add('''import { �it.toAutoCompleteDTOName� } from './�entity.toEntityWebModelName�';''')
		]
		
		if (entity.hasSumFields) {
			imports.add('''import { �entitySumFieldsClassName� } from './�entity.toEntityWebModelName�';''')
		}
		
		val hasAnalitycs = entity.hasAnalitycs
		if (hasAnalitycs) {
			imports.add('''import { �WebAnalitycsGenerator.SERVICE_CLASS_NAME� } from './../../../../�Utils.WEB_ANALITYCS_DIR��WebAnalitycsGenerator.SERVICE_NAME�';''')
		}
		
		imports.add("import { environment } from 'src/environments/environment';")
		
		if (!fkSlots.empty) {
			fkSlots.getDistinctSlotsByEntityName.forEach[ 
				imports.add(it.resolveSlotAutocompleteImportForWeb)
			]
		}
		
		
		val ruleMakeCopies = entity.ruleMakeCopies
		
		val ruleFormActionsWithFunction = entity.ruleFormActionsWithFunction
		val hasTimeFields = entity.hasTime
		
		val body = '''
		
		@Injectable()
		export class �serviceName� {
			
			url = environment.apiUrl + '/�service.domain�/�service.name�/entities/�varName�';
			
			constructor(
				�IF hasAnalitycs�
				private analitycs: �WebAnalitycsGenerator.SERVICE_CLASS_NAME�,
				�ENDIF� 
				private http: HttpClientWithToken) { 
				// Generated code.
			}
			
			// TODO: Provis�rio
			private getHeaders(): Headers {
				const headers = new Headers();
			    
			    headers.append('Content-Type', 'application/json');
			    return headers;
			}
			
			create(�varName�: �dtoName�): Promise<�dtoName�> {
				�IF hasTimeFields�
				�entity.normalizeTimeFields�
				�ENDIF�
				const headers = this.getHeaders();
				�entity.generateAnalitycsSendEvent('create')�
			    return this.http.post(this.url, �varName�, { headers })
			    .toPromise()
			    .then(response => {
			      const created = response as �dtoName�;
			      �IF entity.hasEntitySlots�this.adjustNullEntitySlots([created]);�ENDIF�
			      �IF entity.hasDate�this.adjustEntityDates([created]);�ENDIF�
			      return created;
			    });
			}
			
			update(�varName�: �dtoName�): Promise<�dtoName�> {
				�IF hasTimeFields�
				�entity.normalizeTimeFields�
				�ENDIF�
			    const headers = this.getHeaders();
				�entity.generateAnalitycsSendEvent('update')�
			    return this.http.put(`${this.url}/${�varName�.�entity.id.fieldName�}`, �varName�, { headers })
			    .toPromise()
			    .then(response => {
			      const updated = response as �dtoName�;
			      �IF entity.hasEntitySlots�this.adjustNullEntitySlots([updated]);�ENDIF�
			      �IF entity.hasDate�this.adjustEntityDates([updated]);�ENDIF�
			      return updated;
			    });
			}
			
			delete(id: string): Promise<void> {
				�entity.generateAnalitycsSendEvent('delete')�
			    return this.http.delete(`${this.url}/${id}`)
			    .toPromise()
			    .then(() => null);
			}
			
			retrieve(id: string): Promise<�dtoName�> {
				�entity.generateAnalitycsSendEvent('retrieve')�
			    const headers = this.getHeaders();
			    return this.http.get<�dtoName�>(`${this.url}/${id}`, { headers })
			    .toPromise()
			    .then(response => {
			      const �varName� = response as �dtoName�;
			      �IF entity.hasEntitySlots�this.adjustNullEntitySlots([�varName�]);�ENDIF�
			      �IF entity.hasDate�this.adjustEntityDates([�varName�]);�ENDIF�
			      return �varName�;
			    });
			}
			
			�ruleActions.map[generateRuleActions].join�
			�ruleMakeCopies.map[generateRuleMakeCopiesActions].join�
			�ruleFormActionsWithFunction.map[generateRuleFormActionsWithFunction].join�
			
			�IF entity.hasDate�
			private adjustEntityDates(entityList: �dtoName�[]) {
				entityList.forEach(�varName� => {
				      �entity.slots.filter[it.hasDate && !it.implicit].map[it |
				      '''
				      if (�varName�.�it.fieldName�) {
				        �varName�.�it.fieldName� = moment(�varName�.�it.fieldName�, '�it.formatMask�').toDate();
				      }
				      	
				      '''
				      ].join('\r\n')�
				});
			}
			�ENDIF�
			
			�IF entity.hasTime�
			
			�getTimeAsStringMethodName�(timeCandidate: any): string {
			    if (timeCandidate === null) {
			      return null;
			    }
			
			    if (typeof timeCandidate === 'string') {
			      return timeCandidate;
			    }
			    const result = moment(timeCandidate).format('HH:mm');
			    return result;
			
			}
			�ENDIF�
			
			�IF entity.hasEntitySlots�
			private adjustNullEntitySlots(entityList: �dtoName�[]) {
				/*entityList.forEach(�varName� => {
				      �entity.slots.filter[it.isEntity].map[it |
				      '''
				      if (!�varName�.�it.fieldName�) {
				        �varName�.�it.fieldName� = new �it.asEntity.toDtoName�();
				      }
				      	
				      '''
				      ].join('\r\n')�
				});*/
			}
			�ENDIF�
			
			autoComplete(query: string): Promise<�entity.toAutoCompleteName�[]> {
			    const headers = this.getHeaders();
			
			    let params = new HttpParams();
			    params = params.set('query', query);
				�entity.generateAnalitycsSendEvent('autoComplete', 'JSON.stringify(params)', true)�
			    return this.http.get<�entity.toAutoCompleteName�[]>(`${this.url}/autoComplete`, { headers, params })
			      .toPromise()
			      .then(response => {
			        const result = response as �entity.toAutoCompleteName�[];
			        return result;
			      });
			
			}
			
			�IF !fkSlots.empty�
									
			// Begin relationships autoComplete 
			�fkSlots.map[it.generateSlotAutoCompleteMethod].join�
			// End relationships autoComplete
			
			�ENDIF�
						
			�IF entity.hasListFilterMany�
			�entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoComplete].join�
			�ENDIF�
			
			�varName�List(�varName�ListFilter: �dtoName�ListFilter): Promise<any> {
			    const headers = this.getHeaders();
			
			    const params = this.mountAndGetSearchParams(�varName�ListFilter);
				�entity.generateAnalitycsSendEvent(varName + 'List', 'JSON.stringify(params)', true)�
			    return this.http.get<any>(this.url, { headers, params })
			      .toPromise()
			      .then(response => {
			        const data = response;
			        const items = data.content; /* array of �dtoName� */
			        const totalElements = data.totalElements;
			
			        �IF entity.hasEntitySlots�this.adjustNullEntitySlots(items);�ENDIF�
			        �IF entity.hasDate�this.adjustEntityDates(items);�ENDIF�
			
			        const result = {
			          items,
			          totalElements
			        };
			
			        return result;
			      });
			}
			
			�IF entity.hasSumFields�
			
			get�entitySumFieldsClassName�(�entity.toEntityListFilterName�: �entity.toEntityListFilterClassName�): Promise<�entitySumFieldsClassName�> {
			    const headers = this.getHeaders();
				const params = this.mountAndGetSearchParams(�entity.toEntityListFilterName�);
			    �entity.generateAnalitycsSendEvent('get' + entitySumFieldsClassName, 'JSON.stringify(params)', true)�
				return this.http.get<any>(`${this.url}/�entitySumFieldsClassName.toFirstLower�`, { headers, params })
				  .toPromise()
				  .then(response => {
				    const result = response;
				    return result;
				  });
			}
			�ENDIF�
			
			mountAndGetSearchParams(�VAR_FILTER�: �dtoName�ListFilter): HttpParams {
			    let params = new HttpParams();
			    if (�VAR_FILTER�.pageNumber) {
			      params = params.set('page', �VAR_FILTER�.pageNumber.toString());
			    }
			
			    if (�VAR_FILTER�.pageSize) {
			      params = params.set('size', �VAR_FILTER�.pageSize.toString());
			    }
				
				�entity.slots.filter[it.hasListFilter].generateSlotsFilters�
				
				�mountCustomParamsListFilter�
			
			    // Sort
			    if (�VAR_FILTER�.sortFields) {
			      // search/nameStartsWith?name=K&sort=name,asc&sort=value,desc
			      
					�VAR_FILTER�.sortFields.forEach(sortField => {
						const sortValue = `${sortField.field},${sortField.order > 0 ? 'asc' : 'desc'}`;
						params = params.append('sort', sortValue);
					});
			    }
			
			    return params;
			}
			
		 	mapToJson(someMap: Map<string, any>) {
		      return JSON.stringify(this.mapToObj(someMap));
		    }
		
		    mapToObj(someMap: Map<string, any>) {
		      const obj = Object.create(null);
		      someMap.forEach((value, key) => {
		        obj[key] = value;
		      });
		      return obj;
		    }
			
			dateToStr(data: Date): string {
			    return moment(data).format('YYYY-MM-DD');
			}
			
			/*** TODO: avaliar se vai ser feito isso.
			replicate�dtoName�(id: string, groupId: string, quantity: number): Promise<boolean> {
			    const headers = this.getHeaders();
			
			    const payload = new Replicate�dtoName�Payload(id, quantity, groupId);
			    return this.http.post(`${this.url}/replicate�dtoName�`, payload, { headers } )
			    .toPromise()
			    .then(response => {
			      return response === true;
			    });
			}
				
			getTotais�VAR_FILTER��dtoName�(�VAR_FILTER�: �dtoName�rListFilter): Promise<Totais�VAR_FILTER��dtoName�> {
			    const headers = this.getHeaders();
				
			    const params = this.mountAndGetSearchParams(�VAR_FILTER�);
				�entity.generateAnalitycsSendEvent('getTotais' + VAR_FILTER + dtoName, 'JSON.stringify(params)', true)�
			    return this.http.get<Totais�VAR_FILTER��dtoName�>(`${this.url}/getTotais�VAR_FILTER��dtoName�`, { headers, params })
			    .toPromise()
			    .then(response => {
			      const result = response as Totais�VAR_FILTER��dtoName�;
			      return result;
			    });
			}
			*/
		}
		
		'''
		
		val source = imports.ln.toString + body
		source
	}
	
	def CharSequence getMountCustomParamsListFilter() {
		'''
		// customParams
		if (filter.customParams && filter.customParams.size > 0) {
			const value = this.mapToJson(filter.customParams);
			params = params.set('customParams', value);
		}
		'''
	}
	
	def CharSequence generateSlotAutoCompleteMethod(Slot slot) {
		val entity = slot.asEntity
		val ownerEntity = slot.ownerEntity
		val slotAutoCompleteName = slot.toSlotAutoCompleteName
		val autoCompleteClassName = entity.toAutoCompleteName
		
		val hasAutoCompleteWithOwnerParams = slot.isAutoCompleteWithOwnerParams
		
		'''
		
		�slotAutoCompleteName�(query: string�IF hasAutoCompleteWithOwnerParams�, �ownerEntity.fieldName�: �ownerEntity.toDtoName��ENDIF�): Promise<�autoCompleteClassName�[]> {
		    const headers = this.getHeaders();
		
		    let params = new HttpParams();
		    params = params.set('query', query);
			�entity.generateAnalitycsSendEvent(slotAutoCompleteName, 'JSON.stringify(params)', true)�
		    return this.http.�IF hasAutoCompleteWithOwnerParams�post�ELSE�get�ENDIF�<�autoCompleteClassName�[]>(`${this.url}/�slotAutoCompleteName�`�IF hasAutoCompleteWithOwnerParams�, �ownerEntity.fieldName��ENDIF�, { headers, params })
		      .toPromise()
		      .then(response => {
		        const result = response as �autoCompleteClassName�[];
		        return result;
		      });
		
		}
		
		'''
	}
	
	def CharSequence generateRuleFormActionsWithFunction(Rule rule) {
		val entity = (rule.owner as Entity)
		val function = rule.apply.ruleFunction
		val methodName = entity.toEntityRuleFormActionsFunctionName(function)
		val dtoName = entity.toDtoName
		val varName = dtoName.toFirstLower
		
		'''
		�methodName�(�varName�: �dtoName�): Promise<�dtoName�> {
		    const headers = this.getHeaders();
			�entity.generateAnalitycsSendEvent(methodName)�
		    return this.http.put(`${this.url}/�methodName�/${�varName�.�entity.id.fieldName�}`, �varName�, { headers })
		    .toPromise()
		    .then(response => {
		      const updated = response as �dtoName�;
		      �IF entity.hasEntitySlots�this.adjustNullEntitySlots([updated]);�ENDIF�
		      �IF entity.hasDate�this.adjustEntityDates([updated]);�ENDIF�
		      return updated;
		    });
		}
		
		'''
	}
	
	def CharSequence generateRuleMakeCopiesActions(Rule rule) {
		val actionName = rule.getRuleActionMakeCopiesName
		val grouperField = rule.ruleMakeCopiesGrouperSlot
		val entity = (rule.owner as Entity)
		
		'''
		 
		�actionName�(id: string, numberOfCopies: Number, referenceFieldInterval: Number, �grouperField.fieldName�: String): Promise<void> {
		    const headers = this.getHeaders();
		      const entityCopy = { id, numberOfCopies, referenceFieldInterval, �grouperField.fieldName� };
		      �entity.generateAnalitycsSendEvent(actionName.toString, 'JSON.stringify(entityCopy)', true)�
			    return this.http.post(`${this.url}/�actionName�`, entityCopy, { headers })
			    .toPromise()
			    .then( () => null);
		}
		'''
	}
	
	def CharSequence generateRuleActions(Rule rule) {
		val actionName = rule.getRuleActionName
		val entity = (rule.owner as Entity)
		
		'''
		 
		�actionName�(id: string): Promise<void> {
			const headers = this.getHeaders();
			�entity.generateAnalitycsSendEvent(actionName.toString)�
			return this.http.put(`${this.url}/�actionName�/${id}`, { headers })
			.toPromise()
			.then(() => null);
		}
		'''
	}
	
	def CharSequence generateListFilterAutoComplete(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		val entity = slot.ownerEntity
		
		'''
		
		�autoComplateName�(query: string): Promise<any> {
		    const headers = this.getHeaders();
		
		    let params = new HttpParams();
		    params = params.set('query', query);
			�entity.generateAnalitycsSendEvent(autoComplateName.toString, 'JSON.stringify(params)', true)�
		    return this.http.get<any>(`${this.url}/�autoComplateName�`, { headers, params })
		      .toPromise()
		      .then(response => {
		        const result = response as �autoComplateName.toFirstUpper�[];
		        return result;
		      });
		
		}
		'''
	}
	
	def CharSequence generateSlotsFilters(Iterable<Slot> slots) {
		'''
		�slots.map[generateSlotFilter].join('\r\n')�
		'''
	}
	
	def CharSequence generateSlotFilter(Slot slot) {
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
			
		val isMany = isMany(slot)
		val isEnum = slot.isEnum
		
		val isBetween = slot.isBetween 
		
		val isEqualTo = slot.isEqualTo
		
		var fieldName = '<unknown>'
		
		// begin isEqualTo
		val pair = slot.getSlotNameAndTypeForWeb
		// val fieldType = pair.key
		val fieldName2 = pair.value
		// end isEqualTo
		
		'''
		�IF isEqualTo�
		// �fieldName = fieldName2�
		if (�VAR_FILTER�.�fieldName�) {
			�IF slot.isNumber�
			const value = �VAR_FILTER�.�fieldName�.toString();
			�ELSEIF slot.isEnum�
			const value = String(�VAR_FILTER�.�fieldName�);
			�ELSE�
			const value = �VAR_FILTER�.�fieldName�;
			�ENDIF�
			params = params.set('�fieldName�', value);
		}
		�ENDIF�
		�IF isMany�
		// �fieldName = slot.fieldName�
		if (�VAR_FILTER�.�fieldName��IF isEnum� && �VAR_FILTER�.�fieldName�.length > 0�ENDIF�) {
			�IF isEnum�
			const �fieldName� = �VAR_FILTER�.�fieldName�.join(',');
			�ELSE�
			const �fieldName� = �VAR_FILTER�.�fieldName�.map(item => item.�fieldName�).join(',');
			�ENDIF�
			params = params.set('�fieldName�', �fieldName�);
		}
		�ELSEIF isNotNull && isNull�
		// �fieldName = slot.fieldName + FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper�
		if (�VAR_FILTER�.�fieldName�) {
			const value = �VAR_FILTER�.�fieldName� ? 'true' : 'false';
			params = params.set('�fieldName�', value);
		}
		
		// �fieldName = slot.fieldName + FilterOperatorEnum.IS_NULL.getName.toFirstUpper�
		if (�VAR_FILTER�.�fieldName�) {
			const value = �VAR_FILTER�.�fieldName� ? 'true' : 'false';
			params = params.set('�fieldName�', value);
		}
		�ELSEIF isNotNull�
		// �fieldName = slot.fieldName + FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper�
		if (�VAR_FILTER�.�fieldName�) {
			const value = �VAR_FILTER�.�fieldName� ? 'true' : 'false';
			params = params.set('�fieldName�', value);
		}
		�ELSEIF isNull�
		// �fieldName = slot.fieldName + FilterOperatorEnum.IS_NULL.getName.toFirstUpper�
		if (�VAR_FILTER�.�fieldName�) {
			const value = �VAR_FILTER�.�fieldName� ? 'true' : 'false';
			params = params.set('�fieldName�', value);
		}
		�ELSEIF isBetween�
		// �fieldName = slot.fieldName + BETWEEN_FROM�
		if (�VAR_FILTER�.�fieldName�) {
		�IF slot.isDate�
			const value = this.dateToStr(�VAR_FILTER�.�fieldName�);
		�ELSEIF slot.isNumber�
			const value = �VAR_FILTER�.�fieldName�.toString();
		�ELSE�
			const value = �VAR_FILTER�.�fieldName�;
		�ENDIF�
			params = params.set('�fieldName�', value);
		}
		
		// �fieldName = slot.fieldName + BETWEEN_TO�
		if (�VAR_FILTER�.�fieldName�) {
		�IF slot.isDate�
			const value = this.dateToStr(�VAR_FILTER�.�fieldName�);
		�ELSEIF slot.isNumber�
			const value = �VAR_FILTER�.�fieldName�.toString();
		�ELSE�
			const value = �VAR_FILTER�.�fieldName�;
		�ENDIF�
			params = params.set('�fieldName�', value);
		}
		�ENDIF�
		'''
	}
	
	def String getSlotValueAsParam(Slot slot) {
		
	}
	
	def void initializeImports(Entity entity) {
		imports.add('''
		import { Injectable } from '@angular/core';
		import { HttpParams } from '@angular/common/http';
		import * as moment from 'moment';
		
		import { HttpClientWithToken } from '../../../../security/http-client-token';
		''')
	}
	
	def CharSequence generateAnalitycsSendEvent(Entity entity, String action) {
		val label = '''�action� �entity.name�'''
		entity.generateAnalitycsSendEvent(action, label, false)
	}
	
	def CharSequence generateAnalitycsSendEvent(Entity entity, String action, String label, boolean labelAsObject) {
		if (entity.hasAnalitycs) {
			val category = '''�entity.service.domain�.�entity.service.name�.�entity.name�''' 
			val label_ = if (label !== null) label else '''�action� �entity.name�'''
			generateAnalitycsSendEvent(category, action, label_, labelAsObject)
		}
		else {
			''''''
		}
	}
	
	def CharSequence generateAnalitycsSendEvent(String category, String action, String label, boolean labelAsObject) {
		val label_ = if (labelAsObject) label else "'" + label + "'"
		'''
		this.analitycs.sendEvent('�category�', '�action�', �label_�);
		'''
	}
	
}