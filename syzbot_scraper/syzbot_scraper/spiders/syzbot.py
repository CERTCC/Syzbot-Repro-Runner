# -*- coding: utf-8 -*-
import scrapy


class SyzbotSpider(scrapy.Spider):
    name = 'syzbot'
    allowed_domains = ['syzkaller.appspot.com']
    
    def __init__(self, *args, **kwargs):
        super(SyzbotSpider,self).__init__(*args,**kwargs)
        self.bugid = kwargs.get('bugid')
        self.start_urls = ['https://syzkaller.appspot.com/bug?id='+self.bugid]

    def parse(self, response):
        row = response.css('.list_table').xpath('(.//tbody/tr)[1]/td')
        for td in row:
            if(td.css('.config')):
                yield response.follow(td.css('a::attr(href)').get(),callback=self.parse_config)
            if(td.css('.tag')):
                title_attr_val = td.css('td::attr(title)').get()
                if(title_attr_val):
                    commit = title_attr_val.split('\n')[0]
                    f = open("meta/"+self.bugid+".kernel_commit",'w')
                    f.write(commit)
                    f.close()

            if(td.css('.repro')):
                r = response.follow(td.css('a::attr(href)').get(),callback=self.parse_repro)
                r.meta['type'] = td.css('a::text').get()
                yield r


    def parse_config(self,response):
        fname = "meta/"+self.bugid+".config"
        f = open(fname,'w')
        f.write(response.body.decode(response.encoding))
        f.close()

    def parse_repro(self,response):
        repro_type = response.meta['type'].lower()
        if(repro_type=='c'):
            fname = "crashers/"+self.bugid+'.'+repro_type
        else:
            fname = "meta/"+self.bugid+'.'+repro_type
        
        f = open(fname,'w')
        f.write(response.body.decode(response.encoding))
        f.close()